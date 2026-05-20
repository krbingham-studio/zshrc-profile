import { readFileSync, readdirSync, existsSync } from 'fs'
import { join } from 'path'
import { homedir, platform } from 'os'
import { execSync } from 'child_process'

const HOME = homedir()
const IS_MAC = platform() === 'darwin'

// VS Code stores extensions and settings in different locations per platform
const VSCODE_EXTENSIONS_DIR = IS_MAC
  ? join(HOME, '.vscode', 'extensions')
  : join(HOME, '.vscode-server', 'extensions')

const VSCODE_SETTINGS_DIR = IS_MAC
  ? join(HOME, 'Library', 'Application Support', 'Code', 'User')
  : join(HOME, '.config', 'Code', 'User')

// Common git root locations across platforms
const GIT_ROOTS = [
  join(HOME, 'Git'),
  join(HOME, 'Developer'),
  join(HOME, 'Projects'),
  join(HOME, 'code'),
  join(HOME, 'Documents', 'GitHub'),
].filter(existsSync)

function readJson(path) {
  try {
    // Strip single-line comments before parsing (config.json has a // header)
    const raw = readFileSync(path, 'utf8').replace(/^\s*\/\/.*$/mg, '')
    return JSON.parse(raw)
  } catch {
    return null
  }
}

function readAccount() {
  const cfg = readJson(join(HOME, '.copilot', 'config.json'))
  if (!cfg) return null
  return {
    firstLaunchAt: cfg.firstLaunchAt ?? null,
    trustedFolders: (cfg.trustedFolders ?? []).length,
  }
}

function readMcpServers() {
  const mcpPath = join(VSCODE_SETTINGS_DIR, 'mcp.json')
  const mcp = readJson(mcpPath)
  if (!mcp?.servers) return []

  return Object.entries(mcp.servers).map(([name, cfg]) => ({
    name,
    type: cfg.url ? (cfg.url.includes('sse') ? 'sse' : 'http') : 'command',
    url: cfg.url ?? null,
    command: cfg.command ? [cfg.command, ...(cfg.args ?? [])].join(' ') : null,
    authStatus: 'unknown',
  }))
}

function readExtensions() {
  const extensionsDir = VSCODE_EXTENSIONS_DIR
  if (!existsSync(extensionsDir)) return []

  const seen = new Set()
  const results = []
  try {
    for (const entry of readdirSync(extensionsDir)) {
      if (!entry.startsWith('github.copilot')) continue
      const pkg = readJson(join(extensionsDir, entry, 'package.json'))
      if (!pkg?.version || seen.has(pkg.version)) continue
      seen.add(pkg.version)
      results.push({ name: entry.replace(/-[\d.]+$/, ''), version: pkg.version })
    }
  } catch { /* ignore */ }
  return results.sort((a, b) => b.version.localeCompare(a.version, undefined, { numeric: true }))
}

function readCli() {
  // brew install copilot-cli installs binary named 'copilot'
  // Output: "GitHub Copilot CLI 1.0.49."
  try {
    const out = execSync('copilot --version 2>/dev/null', { encoding: 'utf8', timeout: 3000 })
    const match = out.match(/(\d+\.\d+\.\d+)/)
    if (match) return { installed: true, version: match[1], source: 'brew' }
  } catch { /* not installed via brew */ }

  // Fall back to gh extension
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
  return {
    account: readAccount(),
    mcpServers: readMcpServers(),
    extensions,
    skills: [],
    instructions: readInstructions(),
    cli,
    installed: extensions.length > 0 || cli.installed,
  }
}
