import { readFileSync, readdirSync, existsSync } from 'fs'
import { join } from 'path'
import { homedir, platform } from 'os'
import { execSync } from 'child_process'

const HOME = homedir()
const IS_MAC = platform() === 'darwin'

const COPILOT_HOME = process.env.COPILOT_HOME ?? join(HOME, '.copilot')

const VSCODE_EXTENSIONS_DIR = IS_MAC
  ? join(HOME, '.vscode', 'extensions')
  : join(HOME, '.vscode-server', 'extensions')

const VSCODE_SETTINGS_DIR = IS_MAC
  ? join(HOME, 'Library', 'Application Support', 'Code', 'User')
  : join(HOME, '.config', 'Code', 'User')

const GIT_ROOTS = [
  join(HOME, 'Git'),
  join(HOME, 'Developer'),
  join(HOME, 'Projects'),
  join(HOME, 'code'),
  join(HOME, 'Documents', 'GitHub'),
].filter(existsSync)

function readJson(path) {
  try {
    const raw = readFileSync(path, 'utf8').replace(/^\s*\/\/.*$/mg, '')
    return JSON.parse(raw)
  } catch {
    return null
  }
}

function readAccount() {
  const cfg = readJson(join(COPILOT_HOME, 'config.json'))
  if (!cfg) return null
  return {
    firstLaunchAt: cfg.firstLaunchAt ?? null,
    trustedFolders: (cfg.trustedFolders ?? []).length,
  }
}

const AUTH_KEY = /token|key|secret|password|auth|credential|bearer/i

function inferAuthStatus(s) {
  const type = s.url ? (s.url.includes('sse') ? 'sse' : 'http') : 'command'

  // Local command servers don't require remote auth
  if (type === 'command') return 'ok'

  // HTTP/SSE: check if credentials are configured
  const hasHeaderAuth = s.headers && Object.keys(s.headers).some(k => AUTH_KEY.test(k))
  const hasEnvAuth = s.env && Object.values(s.env).some(v => typeof v === 'string' && v.length > 0)
    && Object.keys(s.env).some(k => AUTH_KEY.test(k))

  if (hasHeaderAuth || hasEnvAuth) return 'ok'

  // Remote server with no credentials configured
  return 'needs-auth'
}

function mcpServerShape(name, s, source) {
  const type = s.url ? (s.url.includes('sse') ? 'sse' : 'http') : 'command'
  return {
    name,
    type,
    url: s.url ?? null,
    command: s.command ? [s.command, ...(s.args ?? [])].join(' ') : null,
    authStatus: inferAuthStatus(s),
    source,
  }
}

function readCliMcpServers() {
  const cfg = readJson(join(COPILOT_HOME, 'mcp-config.json'))
  if (!cfg?.mcpServers) return []
  return Object.entries(cfg.mcpServers).map(([name, s]) => mcpServerShape(name, s, 'cli'))
}

function readVscodeMcpServers() {
  const cfg = readJson(join(VSCODE_SETTINGS_DIR, 'mcp.json'))
  if (!cfg?.servers) return []
  return Object.entries(cfg.servers).map(([name, s]) => mcpServerShape(name, s, 'vscode'))
}

function readExtensions() {
  if (!existsSync(VSCODE_EXTENSIONS_DIR)) return []
  const seen = new Set()
  const results = []
  try {
    for (const entry of readdirSync(VSCODE_EXTENSIONS_DIR)) {
      if (!entry.startsWith('github.copilot')) continue
      const pkg = readJson(join(VSCODE_EXTENSIONS_DIR, entry, 'package.json'))
      if (!pkg?.version || seen.has(pkg.version)) continue
      seen.add(pkg.version)
      results.push({ name: entry.replace(/-[\d.]+$/, ''), version: pkg.version })
    }
  } catch { /* ignore */ }
  return results.sort((a, b) => b.version.localeCompare(a.version, undefined, { numeric: true }))
}

function parseFrontmatter(content) {
  const match = content.match(/^---\n([\s\S]*?)\n---\n?([\s\S]*)$/)
  if (!match) return { meta: {}, body: content.trim() }
  const meta = {}
  for (const line of match[1].split('\n')) {
    const colon = line.indexOf(':')
    if (colon === -1) continue
    meta[line.slice(0, colon).trim()] = line.slice(colon + 1).trim()
  }
  return { meta, body: match[2].trim() }
}

function readSkillsFromDir(dir) {
  if (!existsSync(dir)) return []
  try {
    return readdirSync(dir)
      .filter(f => !f.startsWith('.'))
      .map(f => {
        const skillFile = join(dir, f, 'SKILL.md')
        if (!existsSync(skillFile)) return { name: f, description: null, body: null }
        const raw = readFileSync(skillFile, 'utf8')
        const { meta, body } = parseFrontmatter(raw)
        return { name: meta.name ?? f, description: meta.description ?? null, body }
      })
  } catch {
    return []
  }
}

function readSkills() {
  const seen = new Set()
  const skills = []

  const add = s => { if (!seen.has(s.name)) { seen.add(s.name); skills.push(s) } }

  // Personal skills
  for (const s of readSkillsFromDir(join(COPILOT_HOME, 'skills'))) add(s)
  for (const s of readSkillsFromDir(join(HOME, '.agents', 'skills'))) add(s)

  // Project-level skills (.github/skills/ and .agents/skills/ per repo)
  for (const root of GIT_ROOTS) {
    try {
      for (const repo of readdirSync(root)) {
        for (const subdir of ['.github', '.agents']) {
          for (const s of readSkillsFromDir(join(root, repo, subdir, 'skills'))) add(s)
        }
      }
    } catch { /* skip */ }
  }

  return skills
}

function readAgents() {
  const dir = join(COPILOT_HOME, 'agents')
  if (!existsSync(dir)) return []
  try {
    return readdirSync(dir, { withFileTypes: true })
      .filter(e => e.isFile() && (e.name.endsWith('.md') || e.name.endsWith('.json')))
      .map(e => {
        const content = readFileSync(join(dir, e.name), 'utf8')
        const name = e.name.replace(/\.(md|json)$/, '')
        const lines = content.split('\n').filter(l => l.trim() && !l.startsWith('---') && !l.startsWith('#!'))
        const description = lines.find(l => !l.startsWith('#'))?.trim() ?? ''
        return { name, description, body: content.slice(0, 800) }
      })
  } catch {
    return []
  }
}

function readPlugins() {
  const dir = join(COPILOT_HOME, 'installed-plugins')
  if (!existsSync(dir)) return []
  try {
    return readdirSync(dir, { withFileTypes: true })
      .filter(e => e.isFile() || e.isDirectory())
      .map(e => ({ name: e.name.replace(/\.(json|md)$/, ''), version: null, updatedAt: null }))
  } catch {
    return []
  }
}

function readCli() {
  try {
    const out = execSync('copilot --version 2>/dev/null', { encoding: 'utf8', timeout: 3000 })
    const match = out.match(/(\d+\.\d+\.\d+)/)
    if (match) return { installed: true, version: match[1], source: 'brew' }
  } catch { /* not installed via brew */ }

  try {
    const output = execSync('gh extension list 2>/dev/null', { encoding: 'utf8', timeout: 5000 })
    const line = output.split('\n').find(l => l.toLowerCase().includes('copilot'))
    if (!line) return { installed: false, version: null, source: null }
    const version = line.match(/v[\d.]+/)
    return { installed: true, version: version ? version[0].slice(1) : null, source: 'gh-extension' }
  } catch {
    return { installed: false, version: null, source: null }
  }
}

function readInstructions() {
  const results = []

  function scan(dir, rootDir, depth = 0) {
    if (depth > 3) return
    try {
      for (const entry of readdirSync(dir, { withFileTypes: true })) {
        if (entry.isDirectory() && (!entry.name.startsWith('.') || entry.name === '.github')) {
          scan(join(dir, entry.name), rootDir, depth + 1)
        } else if (entry.name === 'copilot-instructions.md') {
          const fullPath = join(dir, entry.name)
          const content = readFileSync(fullPath, 'utf8')
          const lines = content.split('\n').filter(l => l.trim())
          const description = lines.slice(1).find(l => !l.startsWith('#'))?.trim() ?? ''
          const repoName = fullPath.replace(rootDir + '/', '').split('/')[0]
          results.push({ name: repoName, description, body: content.slice(0, 800) })
        }
      }
    } catch { /* skip unreadable dirs */ }
  }

  for (const root of GIT_ROOTS) scan(root, root)
  return results
}

export function getGithubCopilotData() {
  const extensions = readExtensions()
  const cli = readCli()
  const mcpServers = [...readCliMcpServers(), ...readVscodeMcpServers()]
  return {
    account: readAccount(),
    mcpServers,
    extensions,
    skills: readSkills(),
    agents: readAgents(),
    plugins: readPlugins(),
    instructions: readInstructions(),
    cli,
    installed: extensions.length > 0 || cli.installed,
  }
}
