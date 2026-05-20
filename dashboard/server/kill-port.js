import { execSync } from 'child_process'

const PORT = process.argv[2] ?? '3001'

try {
  if (process.platform === 'darwin') {
    execSync(`lsof -ti tcp:${PORT} | xargs kill -9 2>/dev/null || true`, { stdio: 'ignore', shell: true })
  } else {
    execSync(`fuser -k ${PORT}/tcp 2>/dev/null || true`, { stdio: 'ignore', shell: true })
  }
} catch { /* nothing running on port */ }
