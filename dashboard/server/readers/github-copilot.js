import { readFileSync, readdirSync, existsSync } from 'fs'
import { join } from 'path'
import { homedir } from 'os'
import { execSync } from 'child_process'

function readJson(path) {
  try {
    return JSON.parse(readFileSync(path, 'utf8'))
  } catch {
    return null
  }
}

function readCopilotVersions() {
  const extensionsDir = join(homedir(), '.vscode-server', 'extensions')
  if (!existsSync(extensionsDir)) return []

  const versions = []
  try {
    const entries = readdirSync(extensionsDir)
    for (const entry of entries) {
      if (!entry.startsWith('github.copilot-')) continue
      const pkg = readJson(join(extensionsDir, entry, 'package.json'))
      if (pkg?.version) versions.push(pkg.version)
    }
  } catch {
    // ignore
  }
  return [...new Set(versions)].sort((a, b) => b.localeCompare(a, undefined, { numeric: true }))
}

function readVscodeMcp() {
  const mcpPath = join(homedir(), '.config', 'Code', 'User', 'mcp.json')
  const mcp = readJson(mcpPath)
  if (!mcp || Object.keys(mcp).length === 0) return null
  return mcp
}

function readCliExtension() {
  try {
    const output = execSync('gh extension list 2>/dev/null', { encoding: 'utf8', timeout: 5000 })
    const line = output.split('\n').find(l => l.toLowerCase().includes('copilot'))
    if (!line) return { installed: false, version: null }
    const version = line.match(/v[\d.]+/)
    return { installed: true, version: version ? version[0].slice(1) : null }
  } catch {
    return { installed: false, version: null }
  }
}

export function getGithubCopilotData() {
  const versions = readCopilotVersions()
  return {
    installed: versions.length > 0,
    versions,
    latestVersion: versions[0] ?? null,
    vscodeMcp: readVscodeMcp(),
    cliExtension: readCliExtension(),
  }
}
