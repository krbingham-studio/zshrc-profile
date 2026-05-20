import { readFileSync, readdirSync, existsSync } from 'fs'
import { join } from 'path'
import { homedir } from 'os'

const CLAUDE_DIR = join(homedir(), '.claude')

function readJson(path) {
  try {
    return JSON.parse(readFileSync(path, 'utf8'))
  } catch {
    return null
  }
}

function listDir(path) {
  try {
    return readdirSync(path)
  } catch {
    return []
  }
}

function readAccount() {
  const creds = readJson(join(CLAUDE_DIR, '.credentials.json'))
  if (!creds?.claudeAiOauth) return null
  return {
    subscriptionType: creds.claudeAiOauth.subscriptionType ?? 'unknown',
    credentialExpiry: creds.claudeAiOauth.expiresAt ?? null,
  }
}

function readPlugins() {
  const registry = readJson(join(CLAUDE_DIR, 'plugins', 'installed_plugins.json'))
  if (!registry?.plugins) return []
  return Object.entries(registry.plugins).map(([name, data]) => ({
    name,
    version: data.version ?? null,
    updatedAt: data.updatedAt ?? data.installedAt ?? null,
  }))
}

function readMcpAuthCache() {
  const cache = readJson(join(CLAUDE_DIR, 'mcp-needs-auth-cache.json'))
  if (!cache) return new Set()
  return new Set(Object.keys(cache))
}

async function readMcpServers() {
  const authCache = readMcpAuthCache()
  const servers = []

  const marketplacesDir = join(CLAUDE_DIR, 'plugins', 'marketplaces')
  if (!existsSync(marketplacesDir)) return servers

  const marketplaces = listDir(marketplacesDir)
  for (const marketplace of marketplaces) {
    const externalDir = join(marketplacesDir, marketplace, 'external_plugins')
    if (!existsSync(externalDir)) continue

    const plugins = listDir(externalDir)
    for (const plugin of plugins) {
      const mcpFile = join(externalDir, plugin, '.mcp.json')
      if (!existsSync(mcpFile)) continue
      const mcp = readJson(mcpFile)
      if (!mcp) continue

      for (const [name, config] of Object.entries(mcp)) {
        let type = 'command'
        if (config.type === 'http' || config.url?.startsWith('http')) type = 'http'
        if (config.type === 'sse') type = 'sse'

        const authStatus = authCache.has(name) ? 'needs-auth' : 'ok'

        servers.push({
          name,
          type,
          authStatus,
          url: config.url ?? null,
          command: config.command ? [config.command, ...(config.args ?? [])].join(' ') : null,
        })
      }
    }
  }

  // Also pick up servers from global settings mcpServers if present
  const settings = readJson(join(CLAUDE_DIR, 'settings.json'))
  if (settings?.mcpServers) {
    for (const [name, config] of Object.entries(settings.mcpServers)) {
      if (servers.find(s => s.name === name)) continue
      let type = 'command'
      if (config.type === 'http' || config.url?.startsWith('http')) type = 'http'
      if (config.type === 'sse') type = 'sse'
      servers.push({
        name,
        type,
        authStatus: authCache.has(name) ? 'needs-auth' : 'ok',
        url: config.url ?? null,
        command: config.command ? [config.command, ...(config.args ?? [])].join(' ') : null,
      })
    }
  }

  return servers
}

function readSkills() {
  const skillsDir = join(CLAUDE_DIR, 'skills')
  if (!existsSync(skillsDir)) return []
  return listDir(skillsDir).filter(f => !f.startsWith('.'))
}

function parseFrontmatter(content) {
  const match = content.match(/^---\n([\s\S]*?)\n---\n?([\s\S]*)$/)
  if (!match) return { meta: {}, body: content.trim() }
  const meta = {}
  for (const line of match[1].split('\n')) {
    const colon = line.indexOf(':')
    if (colon === -1) continue
    const key = line.slice(0, colon).trim()
    const value = line.slice(colon + 1).trim()
    meta[key] = value
  }
  return { meta, body: match[2].trim() }
}

function readAgents() {
  const agentsDir = join(CLAUDE_DIR, 'agents')
  if (!existsSync(agentsDir)) return []
  return listDir(agentsDir)
    .filter(f => f.endsWith('.md'))
    .map(f => {
      const raw = readFileSync(join(agentsDir, f), 'utf8')
      const { meta, body } = parseFrontmatter(raw)
      return {
        name: meta.name ?? f.replace(/\.md$/, ''),
        description: meta.description ?? null,
        body,
      }
    })
}

export async function getClaudeCodeData() {
  const [mcpServers] = await Promise.all([readMcpServers()])
  return {
    account: readAccount(),
    mcpServers,
    plugins: readPlugins(),
    skills: readSkills(),
    agents: readAgents(),
  }
}
