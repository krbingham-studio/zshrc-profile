import { existsSync, readdirSync } from 'fs'
import { join } from 'path'
import { homedir } from 'os'

export function getCodexData() {
  const codexDir = join(homedir(), '.codex')
  if (existsSync(codexDir)) {
    return { installed: true, configPath: codexDir }
  }

  const configDir = join(homedir(), '.config')
  if (existsSync(configDir)) {
    try {
      const entries = readdirSync(configDir)
      const openaiEntry = entries.find(e => e.toLowerCase().startsWith('openai'))
      if (openaiEntry) {
        return { installed: true, configPath: join(configDir, openaiEntry) }
      }
    } catch {
      // ignore
    }
  }

  return { installed: false, configPath: null }
}
