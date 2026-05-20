export async function fetchClaudeCode() {
  const res = await fetch('/api/claude-code')
  if (!res.ok) throw new Error('Failed to fetch Claude Code data')
  return res.json()
}

export async function fetchGithubCopilot() {
  const res = await fetch('/api/github-copilot')
  if (!res.ok) throw new Error('Failed to fetch GitHub Copilot data')
  return res.json()
}

export async function fetchCodex() {
  const res = await fetch('/api/codex')
  if (!res.ok) throw new Error('Failed to fetch Codex data')
  return res.json()
}

export async function fetchSystem() {
  const res = await fetch('/api/system')
  if (!res.ok) throw new Error('Failed to fetch system data')
  return res.json()
}

export async function fetchZshProfile() {
  const res = await fetch('/api/zsh-profile')
  if (!res.ok) throw new Error('Failed to fetch ZSH profile data')
  return res.json()
}
