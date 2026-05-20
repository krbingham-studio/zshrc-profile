import { execSync } from 'child_process'

const TOOLS = [
  { name: 'Node.js',   cmd: 'node --version',        parse: v => v.trim() },
  { name: 'npm',       cmd: 'npm --version',          parse: v => `v${v.trim()}` },
  { name: 'pnpm',      cmd: 'pnpm --version',         parse: v => `v${v.trim()}` },
  { name: 'Bun',       cmd: 'bun --version',          parse: v => `v${v.trim()}` },
  { name: 'PHP',       cmd: 'php --version',          parse: v => 'v' + v.match(/PHP ([\d.]+)/)?.[1] },
  { name: 'Composer',  cmd: 'composer --version',     parse: v => 'v' + v.match(/([\d.]+)/)?.[1] },
  { name: 'Python',    cmd: 'python3 --version',      parse: v => 'v' + v.match(/([\d.]+)/)?.[1] },
  { name: 'Git',       cmd: 'git --version',          parse: v => 'v' + v.match(/([\d.]+)/)?.[1] },
  { name: 'Docker',    cmd: 'docker --version',       parse: v => 'v' + v.match(/([\d.]+)/)?.[1] },
  { name: 'gh CLI',    cmd: 'gh --version',           parse: v => 'v' + v.match(/([\d.]+)/)?.[1] },
  { name: 'ZSH',       cmd: 'zsh --version',          parse: v => 'v' + v.match(/([\d.]+)/)?.[1] },
  { name: 'MySQL',     cmd: 'mysql --version',        parse: v => 'v' + v.match(/([\d.]+)/)?.[1] },
  { name: 'Redis',     cmd: 'redis-cli --version',    parse: v => 'v' + v.match(/([\d.]+)/)?.[1] },
  { name: 'uv',        cmd: 'uv --version',           parse: v => 'v' + v.match(/([\d.]+)/)?.[1] },
  { name: 'Rust',      cmd: 'rustc --version',        parse: v => 'v' + v.match(/([\d.]+)/)?.[1] },
  { name: 'Go',        cmd: 'go version',             parse: v => 'v' + v.match(/go([\d.]+)/)?.[1] },
]

function probe(tool) {
  try {
    const raw = execSync(tool.cmd, { encoding: 'utf8', timeout: 3000, stdio: ['ignore', 'pipe', 'pipe'] })
    const version = tool.parse(raw) ?? null
    return { name: tool.name, version, installed: !!version }
  } catch {
    return { name: tool.name, version: null, installed: false }
  }
}

export function getSystemData() {
  return TOOLS.map(probe)
}
