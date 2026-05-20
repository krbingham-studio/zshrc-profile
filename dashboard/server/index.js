import express from 'express'
import cors from 'cors'
import { getClaudeCodeData } from './readers/claude-code.js'
import { getGithubCopilotData } from './readers/github-copilot.js'
import { getCodexData } from './readers/codex.js'
import { getSystemData } from './readers/system.js'
import { getZshProfileData } from './readers/zsh-profile.js'

const app = express()
const PORT = 3001

app.use(cors())

app.get('/api/claude-code', async (req, res) => {
  try {
    const data = await getClaudeCodeData()
    res.json(data)
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

app.get('/api/github-copilot', (req, res) => {
  try {
    res.json(getGithubCopilotData())
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

app.get('/api/codex', (req, res) => {
  try {
    res.json(getCodexData())
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

app.get('/api/system', (req, res) => {
  try {
    res.json(getSystemData())
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

app.get('/api/zsh-profile', (req, res) => {
  try {
    res.json(getZshProfileData())
  } catch (err) {
    res.status(500).json({ error: err.message })
  }
})

app.listen(PORT, () => {
  console.log(`API server running at http://localhost:${PORT}`)
})
