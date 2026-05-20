import { readFileSync, existsSync } from 'fs'
import { join } from 'path'
import { fileURLToPath } from 'url'

const REPO_ROOT = join(fileURLToPath(import.meta.url), '..', '..', '..', '..')
const CONFIG_DIR = join(REPO_ROOT, 'config')

const SENSITIVE = /token|secret|password|passwd|api[_-]?key|auth|credential/i

function readFile(name) {
  const p = join(CONFIG_DIR, name)
  return existsSync(p) ? readFileSync(p, 'utf8') : ''
}

function parseAliases(source, label) {
  const aliases = []
  for (const line of source.split('\n')) {
    const trimmed = line.trim()
    const m = trimmed.match(/^alias\s+([^=\s]+)=['"]?(.*?)['"]?\s*$/)
    if (!m) continue
    aliases.push({ name: m[1], command: m[2].replace(/['"]$/, ''), source: label })
  }
  return aliases
}

function parseExports(source) {
  const exports = []
  for (const line of source.split('\n')) {
    const trimmed = line.trim()
    const m = trimmed.match(/^export\s+([A-Za-z_][A-Za-z0-9_]*)=(.*)$/)
    if (!m) continue
    const key = m[1]
    let value = m[2].trim().replace(/^['"]|['"]$/g, '')
    if (SENSITIVE.test(key)) value = '••••••'
    exports.push({ key, value })
  }
  return exports
}

function parseFunctions(source, label) {
  const fns = []
  const lines = source.split('\n')
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim()
    // match: name() { or function name { or function name() {
    const m = line.match(/^(?:function\s+)?([a-zA-Z_][a-zA-Z0-9_:-]*)(?:\s*\(\s*\))?\s*\{?\s*$/)
    if (!m || m[1] === 'if' || m[1] === 'else' || m[1] === 'elif' || m[1] === 'then') continue
    if (!line.includes('(') && !line.startsWith('function ')) continue

    // look for a comment on the preceding line as a description
    let description = null
    if (i > 0) {
      const prev = lines[i - 1].trim()
      if (prev.startsWith('#') && !prev.startsWith('# ===') && !prev.startsWith('# ---')) {
        description = prev.replace(/^#+\s*/, '')
      }
    }
    fns.push({ name: m[1], description, source: label })
  }
  return fns
}

function parseSections(source) {
  const sections = []
  let current = null
  for (const line of source.split('\n')) {
    const header = line.match(/^#\s*={4,}\s*$|^#\s*-{4,}\s*$/)
    const title = line.match(/^#\s{1,3}(.+)\s*$/)
    if (header) {
      current = null
      continue
    }
    if (title && !sections.find(s => s.title === title[1].trim())) {
      const t = title[1].trim()
      if (t.length > 2 && t.length < 60 && !t.startsWith('=') && !t.startsWith('-')) {
        current = { title: t, aliases: [] }
        sections.push(current)
      }
      continue
    }
    if (current) {
      const m = line.trim().match(/^alias\s+([^=\s]+)=['"]?(.*?)['"]?\s*$/)
      if (m) current.aliases.push({ name: m[1], command: m[2].replace(/['"]$/, '') })
    }
  }
  return sections.filter(s => s.aliases.length > 0)
}

export function getZshProfileData() {
  const aliasesRaw = readFile('aliases.zsh')
  const gitRaw = readFile('git.zsh')
  const functionsRaw = readFile('functions.zsh')
  const exportsRaw = readFile('exports.zsh')

  return {
    aliasSections: parseSections(aliasesRaw),
    gitAliases: parseAliases(gitRaw, 'git.zsh'),
    exports: parseExports(exportsRaw),
    functions: [
      ...parseFunctions(functionsRaw, 'functions.zsh'),
      ...parseFunctions(gitRaw, 'git.zsh'),
    ],
  }
}
