<template>
  <div
    class="app"
    :style="{
      '--dash-accent': accent,
      '--dash-card-pad': '10px 13px',
      '--dash-card-gap': '8px',
      '--dash-section-gap': '20px',
    }"
  >
    <!-- Header -->
    <header class="header">
      <div class="header-texture" aria-hidden="true" />
      <div class="brand-mark">
        <iconify-icon icon="lucide:terminal-square" width="13" height="13" style="color:#1a1208" />
      </div>
      <span class="header-title">
        AI Dev Dashboard
        <span class="header-sub">· {{ refreshedAt }}</span>
      </span>
      <button
        class="refresh-btn"
        :disabled="loading"
        @click="refresh"
        @mouseenter="e => { if (!loading) { e.currentTarget.style.background='rgba(255,255,255,0.04)'; e.currentTarget.style.color='var(--fh-fg-default)'; }}"
        @mouseleave="e => { e.currentTarget.style.background='transparent'; e.currentTarget.style.color='var(--fh-fg-muted)'; }"
      >
        <iconify-icon icon="lucide:rotate-cw" width="12" height="12" :class="{ spinning: loading }" />
        Refresh
      </button>
    </header>

    <!-- Tab nav -->
    <nav class="tabs">
      <button
        v-for="tab in visibleTabs"
        :key="tab.id"
        class="tab"
        :class="{ active: activeTab === tab.id }"
        @click="activeTab = tab.id"
        @mouseenter="e => { if (activeTab !== tab.id) e.currentTarget.style.color = 'var(--fh-fg-default)' }"
        @mouseleave="e => { if (activeTab !== tab.id) e.currentTarget.style.color = 'var(--fh-fg-subtle)' }"
      >
        <iconify-icon :icon="`lucide:${tab.icon}`" width="13" height="13" />
        {{ tab.label }}
        <span v-if="tabBadge(tab.id) > 0" class="tab-badge">{{ tabBadge(tab.id) }}</span>
      </button>
    </nav>

    <!-- Content -->
    <main class="content">
      <div v-if="error" class="error-bar">
        <iconify-icon icon="lucide:alert-circle" width="14" height="14" />
        {{ error }}
      </div>

      <!-- Claude Code -->
      <section v-if="activeTab === 'claude'" class="tool-section">
        <div v-if="!claude" class="loading-state">Loading…</div>
        <template v-else>
          <!-- Account bar -->
          <div class="account-bar">
            <iconify-icon icon="lucide:user" width="15" height="15" style="color:var(--fh-fg-subtle);flex-shrink:0" />
            <span class="account-name">Claude {{ claude.account?.subscriptionType ?? 'Pro' }}</span>
            <span class="account-expiry" v-if="claude.account?.credentialExpiry">
              expires {{ formatDate(claude.account.credentialExpiry) }}
            </span>
          </div>

          <!-- Stats strip -->
          <div class="stats-strip">
            <div v-for="stat in statsItems" :key="stat.label" class="stat-card dash-card">
              <div class="stat-label">{{ stat.label }}</div>
              <div class="stat-val" :style="{ color: stat.color }">{{ stat.val }}</div>
            </div>
          </div>

          <!-- Auth warning -->
          <div v-if="!authDismissed && needsAuthServers.length > 0" class="auth-warning">
            <iconify-icon icon="lucide:alert-triangle" width="14" height="14" style="color:#e8c96a;flex-shrink:0;margin-top:1px" />
            <div class="auth-warning-text">
              <span class="auth-warning-title">{{ needsAuthServers.length }} server{{ needsAuthServers.length > 1 ? 's' : '' }} need authentication</span>
              <span class="auth-warning-names"> — {{ needsAuthServers.map(s => s.name).join(', ') }}</span>
            </div>
            <button class="auth-dismiss" @click="authDismissed = true">✕</button>
          </div>

          <!-- MCP Servers -->
          <div class="section-block">
            <div class="section-head sticky-head">
              <span class="section-label">MCP Servers</span>
              <span class="section-count">{{ claude.mcpServers.length }}</span>
            </div>
            <div class="card-grid">
              <McpServerCard v-for="s in claude.mcpServers" :key="s.name" :server="s" />
            </div>
            <div v-if="!claude.mcpServers.length" class="empty">No MCP servers configured</div>
          </div>

          <!-- Plugins -->
          <div class="section-block">
            <div class="section-head sticky-head">
              <span class="section-label">Plugins</span>
              <span class="section-count">{{ claude.plugins.length }}</span>
            </div>
            <div class="four-col-grid">
              <PluginCard v-for="p in claude.plugins" :key="p.name" :plugin="p" />
            </div>
          </div>

          <!-- Skills -->
          <div class="section-block">
            <div class="section-head sticky-head">
              <span class="section-label">Skills</span>
              <span class="section-count">{{ claude.skills.length }}</span>
            </div>
            <div class="four-col-grid" v-if="claude.skills.length">
              <SkillCard v-for="s in claude.skills" :key="s.name" :skill="s" />
            </div>
            <div v-else class="empty">No skills configured</div>
          </div>

          <!-- Agents -->
          <div class="section-block">
            <div class="section-head sticky-head">
              <span class="section-label">Agents</span>
              <span class="section-count">{{ claude.agents.length }}</span>
            </div>
            <div class="four-col-grid">
              <AgentCard v-for="a in claude.agents" :key="a.name" :agent="a" />
            </div>
            <div v-if="!claude.agents.length" class="empty">No agents configured</div>
          </div>
        </template>
      </section>

      <!-- GitHub Copilot -->
      <section v-if="activeTab === 'copilot'" class="tool-section">
        <div v-if="!copilot" class="loading-state">Loading…</div>
        <template v-else>
          <!-- Account bar -->
          <div class="account-bar" v-if="copilot.account">
            <iconify-icon icon="lucide:github" width="15" height="15" style="color:var(--fh-fg-subtle);flex-shrink:0" />
            <span class="account-name">GitHub Copilot</span>
            <span class="account-expiry" v-if="copilot.account.firstLaunchAt">
              first launch {{ formatDate(copilot.account.firstLaunchAt) }}
            </span>
            <span class="account-expiry" v-if="copilot.cli?.installed">
              · CLI v{{ copilot.cli.version }}
              <span class="source-badge" style="margin-left:4px">{{ copilot.cli.source }}</span>
            </span>
          </div>

          <!-- MCP Servers -->
          <div class="section-block">
            <div class="section-head sticky-head">
              <span class="section-label">MCP Servers</span>
              <span class="section-count">{{ copilot.mcpServers.length }}</span>
            </div>
            <div class="card-grid" v-if="copilot.mcpServers.length">
              <McpServerCard v-for="s in copilot.mcpServers" :key="s.source + s.name" :server="s" :show-source="true" />
            </div>
            <div v-else class="empty">No MCP servers configured</div>
          </div>

          <!-- Plugins (CLI installed-plugins) -->
          <div class="section-block">
            <div class="section-head sticky-head">
              <span class="section-label">Plugins</span>
              <span class="section-count">{{ copilot.plugins.length }}</span>
            </div>
            <div class="four-col-grid" v-if="copilot.plugins.length">
              <PluginCard v-for="p in copilot.plugins" :key="p.name" :plugin="p" />
            </div>
            <div v-else class="empty">No plugins installed</div>
          </div>

          <!-- Extensions (VS Code) -->
          <div class="section-block">
            <div class="section-head sticky-head">
              <span class="section-label">Extensions</span>
              <span class="section-count">{{ copilot.extensions.length }}</span>
            </div>
            <div class="two-col-grid" v-if="copilot.extensions.length">
              <PluginCard v-for="e in copilot.extensions" :key="e.name + e.version" :plugin="e" />
            </div>
            <div v-else class="empty">No VS Code extensions found</div>
          </div>

          <!-- Skills -->
          <div class="section-block">
            <div class="section-head sticky-head">
              <span class="section-label">Skills</span>
              <span class="section-count">{{ copilot.skills.length }}</span>
            </div>
            <div class="four-col-grid" v-if="copilot.skills.length">
              <SkillCard v-for="s in copilot.skills" :key="s.name" :skill="s" />
            </div>
            <div v-else class="empty">No skills configured</div>
          </div>

          <!-- Agents (CLI agents/) -->
          <div class="section-block">
            <div class="section-head sticky-head">
              <span class="section-label">Agents</span>
              <span class="section-count">{{ copilot.agents.length }}</span>
            </div>
            <div class="four-col-grid" v-if="copilot.agents.length">
              <AgentCard v-for="a in copilot.agents" :key="a.name" :agent="a" />
            </div>
            <div v-else class="empty">No agents configured</div>
          </div>

          <!-- Project Instructions (copilot-instructions.md per repo) -->
          <div class="section-block">
            <div class="section-head sticky-head">
              <span class="section-label">Project Instructions</span>
              <span class="section-count">{{ copilot.instructions.length }}</span>
            </div>
            <div class="two-col-grid" v-if="copilot.instructions.length">
              <AgentCard v-for="a in copilot.instructions" :key="a.name" :agent="a" />
            </div>
            <div v-else class="empty">No copilot-instructions.md files found</div>
          </div>
        </template>
      </section>

      <!-- Codex -->
      <section v-if="activeTab === 'codex'" class="tool-section">
        <div v-if="!codex" class="loading-state">Loading…</div>
        <div v-else-if="!codex.installed" class="empty-state">
          <iconify-icon icon="lucide:box" width="44" height="44" style="color:var(--fh-fg-subtle);opacity:0.4" />
          <div class="empty-state-heading">Codex not configured</div>
          <div class="empty-state-sub">No installation detected at <code>~/.codex/</code> or <code>~/.config/openai*</code></div>
          <a href="https://github.com/openai/codex" target="_blank" rel="noopener" class="empty-state-link">View Codex on GitHub →</a>
        </div>
        <template v-else>
          <div class="section-block">
            <div class="section-head sticky-head"><span class="section-label">Codex</span></div>
            <div class="simple-card dash-card">
              <span class="simple-card-name">Codex</span>
              <StatusBadge status="installed" />
              <code class="mono-detail" v-if="codex.configPath">{{ codex.configPath }}</code>
            </div>
          </div>
        </template>
      </section>

      <!-- System -->
      <section v-if="activeTab === 'system'" class="tool-section">
        <div v-if="!system" class="loading-state">Loading…</div>
        <template v-else>
          <div class="section-block">
            <div class="section-head sticky-head">
              <span class="section-label">Dev Tools</span>
              <span class="section-count">{{ system.filter(t => t.installed).length }} / {{ system.length }}</span>
            </div>
            <div class="two-col-grid">
              <div v-for="tool in system" :key="tool.name" class="card dash-card">
                <div class="card-header-row">
                  <span class="card-name-mono">{{ tool.name }}</span>
                  <StatusBadge :status="tool.installed ? 'installed' : 'not-installed'" />
                </div>
                <div class="detail-mono" v-if="tool.version">{{ tool.version }}</div>
              </div>
            </div>
          </div>
        </template>
      </section>

      <!-- ZSH Profile -->
      <section v-if="activeTab === 'zsh'" class="tool-section">
        <div v-if="!zsh" class="loading-state">Loading…</div>
        <template v-else>

          <!-- Aliases -->
          <div class="section-block">
            <div class="section-head sticky-head">
              <span class="section-label">Aliases</span>
              <span class="section-count">{{ zsh.aliasSections.reduce((n, s) => n + s.aliases.length, 0) }}</span>
            </div>
            <div class="alias-groups">
              <div v-for="section in zsh.aliasSections" :key="section.title" class="alias-group">
                <div class="alias-group-title">{{ section.title }}</div>
                <div class="alias-table">
                  <div v-for="a in section.aliases" :key="a.name" class="alias-row">
                    <code class="alias-name">{{ a.name }}</code>
                    <code class="alias-cmd">{{ a.command }}</code>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Exports -->
          <div class="section-block">
            <div class="section-head sticky-head">
              <span class="section-label">Exports</span>
              <span class="section-count">{{ zsh.exports.length }}</span>
            </div>
            <div class="alias-table exports-table">
              <div v-for="e in zsh.exports" :key="e.key" class="alias-row">
                <code class="export-key">{{ e.key }}</code>
                <code class="alias-cmd" :class="{ redacted: e.value === '••••••' }">{{ e.value }}</code>
              </div>
            </div>
          </div>

          <!-- Functions -->
          <div class="section-block">
            <div class="section-head sticky-head">
              <span class="section-label">Functions</span>
              <span class="section-count">{{ zsh.functions.length }}</span>
            </div>
            <div class="two-col-grid">
              <div v-for="fn in zsh.functions" :key="fn.name + fn.source" class="card dash-card">
                <div class="card-header-row">
                  <span class="card-name-mono">{{ fn.name }}</span>
                  <span class="source-badge">{{ fn.source }}</span>
                </div>
                <div class="fn-desc" v-if="fn.description">{{ fn.description }}</div>
              </div>
            </div>
          </div>

        </template>
      </section>
    </main>

    <!-- Toast -->
    <transition name="toast">
      <div v-if="toast" class="toast">
        <iconify-icon :icon="`lucide:${toast.icon || 'check'}`" width="14" height="14" style="color:var(--dash-accent);flex-shrink:0" />
        {{ toast.msg }}
      </div>
    </transition>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { fetchClaudeCode, fetchGithubCopilot, fetchCodex, fetchSystem, fetchZshProfile } from './api.js'
import StatusBadge from './components/StatusBadge.vue'
import McpServerCard from './components/McpServerCard.vue'
import PluginCard from './components/PluginCard.vue'
import SkillCard from './components/SkillCard.vue'
import AgentCard from './components/AgentCard.vue'

const ACCENT = '#F57F2F'
const accent = ref(ACCENT)

const tabs = [
  { id: 'claude',  label: 'Claude Code',    icon: 'cpu',        installed: () => !!claude.value },
  { id: 'copilot', label: 'GitHub Copilot', icon: 'github',     installed: () => copilot.value?.installed ?? false },
  { id: 'codex',   label: 'Codex',          icon: 'box',        installed: () => codex.value?.installed ?? false },
  { id: 'system',  label: 'System',         icon: 'settings-2', installed: () => true },
  { id: 'zsh',     label: 'ZSH Profile',    icon: 'terminal',   installed: () => true },
]

const visibleTabs = computed(() => tabs.filter(t => t.installed()))

const activeTab = ref('claude')
const loading = ref(false)
const error = ref(null)
const refreshedAt = ref('just now')
const claude = ref(null)
const copilot = ref(null)
const codex = ref(null)
const system = ref(null)
const zsh = ref(null)
const authDismissed = ref(false)
const toast = ref(null)
let toastTimer = null

const needsAuthServers = computed(() =>
  claude.value?.mcpServers.filter(s => s.authStatus === 'needs-auth') ?? []
)

const statsItems = computed(() => {
  if (!claude.value) return []
  const connected  = claude.value.mcpServers.filter(s => s.authStatus === 'ok').length
  const authNeeded = needsAuthServers.value.length
  return [
    { label: 'MCPs connected', val: `${connected} / ${claude.value.mcpServers.length}`, color: '#4ec77a' },
    { label: 'Auth pending',   val: authNeeded, color: authNeeded > 0 ? '#e8c96a' : '#4ec77a' },
    { label: 'Agents',         val: claude.value.agents.length,  color: accent.value },
    { label: 'Skills',         val: claude.value.skills.length,  color: 'var(--fh-fg-muted)' },
  ]
})

function tabBadge(id) {
  if (id === 'claude') return needsAuthServers.value.length
  if (id === 'system') return system.value?.filter(t => !t.installed).length ?? 0
  return 0
}

function showToast(detail) {
  toast.value = detail
  if (toastTimer) clearTimeout(toastTimer)
  toastTimer = setTimeout(() => { toast.value = null }, 2500)
}

function handleToastEvent(e) { showToast(e.detail) }

function handleKeydown(e) {
  if (e.key !== 'ArrowRight' && e.key !== 'ArrowLeft') return
  const ids = visibleTabs.value.map(t => t.id)
  const i = ids.indexOf(activeTab.value)
  activeTab.value = e.key === 'ArrowRight'
    ? ids[(i + 1) % ids.length]
    : ids[(i - 1 + ids.length) % ids.length]
}

async function load() {
  loading.value = true
  error.value = null
  try {
    ;[claude.value, copilot.value, codex.value, system.value, zsh.value] = await Promise.all([
      fetchClaudeCode(), fetchGithubCopilot(), fetchCodex(), fetchSystem(), fetchZshProfile(),
    ])
    refreshedAt.value = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    // If active tab is now hidden, jump to first visible tab
    if (!visibleTabs.value.find(t => t.id === activeTab.value)) {
      activeTab.value = visibleTabs.value[0]?.id ?? 'claude'
    }
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

function refresh() {
  load().then(() => showToast({ msg: 'Dashboard refreshed', icon: 'check' }))
}

function formatDate(iso) {
  if (!iso) return ''
  return new Date(iso).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })
}

onMounted(() => {
  load()
  window.addEventListener('dash-toast', handleToastEvent)
  window.addEventListener('keydown', handleKeydown)
})
onUnmounted(() => {
  window.removeEventListener('dash-toast', handleToastEvent)
  window.removeEventListener('keydown', handleKeydown)
})
</script>

<style>
/* ── Forgehelm Design System tokens ───────────────────────────────── */
:root {
  --fh-forge-black:    #1a1208;
  --fh-forge-charcoal: #2a2015;
  --fh-parchment:      #faf6ef;
  --fh-deep-text:      #1c1a17;
  --fh-iron:           #6b6355;
  --fh-ember:          #F57F2F;
  --fh-ember-hover:    #FF944F;
  --fh-ember-pressed:  #D96B1F;
  --fh-gold:           #e8c96a;
  --fh-divider:        #d4c5a9;
  --fh-forge-glow:     #3d2e12;

  --fh-polished-iron:  #3F4349;
  --fh-glacial-cyan:   #9FDFF3;
  --fh-soft-frost:     #E3EBF3;
  --fh-steel-gray:     #D9DEE3;
  --fh-draft-gray:     #A3AAB2;

  --fh-bg-canvas:   #1a1208;
  --fh-bg-panel:    #2a2015;
  --fh-bg-elevated: #2f2519;
  --fh-bg-inset:    #14100a;
  --fh-bg-surface:  #faf6ef;
  --fh-bg-muted:    rgba(255,255,255,0.04);

  --fh-fg-default:   #faf6ef;
  --fh-fg-muted:     #A3AAB2;
  --fh-fg-subtle:    #7a7064;
  --fh-fg-inverse:   #1c1a17;
  --fh-fg-accent:    #F57F2F;
  --fh-fg-highlight: #e8c96a;

  --fh-border-subtle:        #3d2e12;
  --fh-border-default:       #6b6355;
  --fh-border-high-contrast: #d4c5a9;

  --fh-error:   #3a1d1d; --fh-error-fg:   #f4a8a8; --fh-error-stroke:   #c93e3e;
  --fh-success: #1d3a2a; --fh-success-fg: #a8e6c0; --fh-success-stroke: #4ec77a;
  --fh-info:    #12233d; --fh-info-fg:    #9FDFF3; --fh-info-stroke:    #4b8fd1;
  --fh-warning: #3a2a12; --fh-warning-fg: #e8c96a; --fh-warning-stroke: #d4a64e;

  --fh-font-display: Georgia, "Times New Roman", serif;
  --fh-font-body:    "Inter", -apple-system, BlinkMacSystemFont, sans-serif;
  --fh-font-mono:    "JetBrains Mono", ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;

  --fh-radius-sm: 2px; --fh-radius-md: 4px; --fh-radius-lg: 6px;
  --fh-radius-xl: 10px; --fh-radius-pill: 9999px;

  --fh-shadow-xs: 0 1px 2px rgba(0,0,0,0.40);
  --fh-shadow-sm: 0 2px 4px rgba(0,0,0,0.45), 0 1px 2px rgba(0,0,0,0.35);
  --fh-shadow-md: 0 6px 14px rgba(0,0,0,0.50), 0 2px 4px rgba(0,0,0,0.30);

  --fh-inset-hairline: inset 0 1px 0 rgba(255,255,255,0.04);
}

*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

html, body, #app {
  height: 100%;
  font-family: var(--fh-font-body);
  background: var(--fh-bg-canvas);
  color: var(--fh-fg-default);
  -webkit-font-smoothing: antialiased;
}

button { font: inherit; cursor: pointer; }

.dash-card {
  box-shadow: var(--fh-shadow-xs), var(--fh-inset-hairline);
  transition: box-shadow 150ms ease;
  border: 1px solid var(--fh-border-subtle);
}
.dash-card:hover { box-shadow: var(--fh-shadow-md), var(--fh-inset-hairline); }

@keyframes spin { from { transform: rotate(0deg); } to { transform: rotate(360deg); } }
.spinning { animation: spin 700ms linear infinite; display: inline-flex; }

@keyframes slideUp {
  from { opacity: 0; transform: translateY(8px); }
  to   { opacity: 1; transform: translateY(0); }
}

::-webkit-scrollbar { width: 6px; height: 6px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.10); border-radius: 3px; }
::-webkit-scrollbar-thumb:hover { background: rgba(255,255,255,0.18); }

.toast-enter-active { animation: slideUp 180ms ease; }
.toast-leave-active { transition: opacity 150ms; }
.toast-leave-to { opacity: 0; }
</style>

<style scoped>
.app {
  display: flex;
  flex-direction: column;
  height: 100vh;
  overflow: hidden;
  background: var(--fh-bg-canvas);
}

/* Header */
.header {
  position: relative;
  overflow: hidden;
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 0 20px;
  height: 48px;
  flex-shrink: 0;
  background: var(--fh-bg-panel);
  border-bottom: 1px solid var(--fh-border-subtle);
}
.header-texture {
  position: absolute;
  inset: 0;
  pointer-events: none;
  background-image: url('/assets/texture-blueprint-knots.png');
  background-size: 180px 180px;
  opacity: 0.055;
  mix-blend-mode: lighten;
}
.brand-mark {
  position: relative;
  width: 24px; height: 24px;
  border-radius: var(--fh-radius-md);
  background: var(--dash-accent);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}
.header-title {
  position: relative;
  font-family: var(--fh-font-mono);
  font-size: 13px;
  font-weight: 600;
  color: var(--fh-fg-default);
  flex: 1;
  letter-spacing: 0.2px;
}
.header-sub {
  margin-left: 10px;
  font-size: 11px;
  font-weight: 400;
  color: var(--fh-fg-subtle);
}
.refresh-btn {
  position: relative;
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 11px;
  border: 1px solid var(--fh-border-default);
  border-radius: var(--fh-radius-md);
  background: transparent;
  color: var(--fh-fg-muted);
  font-size: 12px;
  font-weight: 500;
  font-family: var(--fh-font-body);
  transition: background 150ms, border-color 150ms, color 150ms;
}
.refresh-btn:disabled { opacity: 0.5; cursor: default; }

/* Tabs */
.tabs {
  display: flex;
  flex-shrink: 0;
  padding: 0 20px;
  background: var(--fh-bg-panel);
  border-bottom: 1px solid var(--fh-border-subtle);
}
.tab {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  padding: 9px 14px;
  margin-bottom: -1px;
  background: transparent;
  border: none;
  border-bottom: 2px solid transparent;
  color: var(--fh-fg-subtle);
  font-size: 13px;
  font-weight: 500;
  font-family: var(--fh-font-body);
  cursor: pointer;
  transition: color 150ms, border-color 150ms;
  white-space: nowrap;
}
.tab.active {
  color: var(--dash-accent);
  border-bottom-color: var(--dash-accent);
  font-weight: 600;
}
.tab-badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 16px;
  height: 16px;
  padding: 0 4px;
  border-radius: 9999px;
  font-size: 10px;
  font-weight: 700;
  background: #3a2a12;
  color: #e8c96a;
  border: 1px solid #d4a64e;
  line-height: 1;
}

/* Content */
.content { flex: 1; overflow-y: auto; padding: 20px; }
.tool-section { display: flex; flex-direction: column; gap: var(--dash-section-gap, 20px); }

/* Account bar */
.account-bar {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 16px;
  background: var(--fh-bg-panel);
  border-radius: var(--fh-radius-md);
  border-left: 3px solid var(--dash-accent);
  border: 1px solid var(--fh-border-subtle);
  border-left: 3px solid var(--dash-accent);
  box-shadow: var(--fh-shadow-xs);
}
.account-name { font-weight: 600; font-size: 13px; color: var(--fh-fg-default); flex: 1; }
.account-expiry { font-size: 11px; color: var(--fh-fg-subtle); font-family: var(--fh-font-mono); }

/* Stats strip */
.stats-strip { display: grid; grid-template-columns: repeat(4, 1fr); gap: var(--dash-card-gap, 8px); }
.stat-card {
  background: var(--fh-bg-panel);
  border-radius: var(--fh-radius-md);
  padding: 10px 14px;
}
.stat-label {
  font-size: 10px;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: var(--fh-fg-subtle);
  font-weight: 600;
  margin-bottom: 6px;
  white-space: nowrap;
}
.stat-val {
  font-family: var(--fh-font-mono);
  font-size: 22px;
  font-weight: 700;
  line-height: 1;
}

/* Auth warning */
.auth-warning {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  padding: 9px 10px 9px 14px;
  background: #3a2a12;
  border-radius: var(--fh-radius-md);
  border: 1px solid #d4a64e;
  font-size: 12px;
  line-height: 1.5;
}
.auth-warning-text { flex: 1; }
.auth-warning-title { font-weight: 600; color: #e8c96a; }
.auth-warning-names { color: rgba(232,201,106,0.65); margin-left: 4px; }
.auth-dismiss {
  background: none;
  border: none;
  color: #d4a64e;
  cursor: pointer;
  font-size: 15px;
  opacity: 0.6;
  padding: 0 4px;
  line-height: 1;
  flex-shrink: 0;
  transition: opacity 120ms;
}
.auth-dismiss:hover { opacity: 1; }

/* Section heading */
.section-block { display: flex; flex-direction: column; gap: 10px; }
.section-head {
  display: flex;
  align-items: center;
  gap: 8px;
}
.sticky-head {
  position: sticky;
  top: 0;
  z-index: 10;
  background: var(--fh-bg-canvas);
  padding-top: 2px;
  padding-bottom: 4px;
}
.section-label {
  font-family: var(--fh-font-body);
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: var(--fh-fg-subtle);
  user-select: none;
  white-space: nowrap;
}
.section-count {
  font-family: var(--fh-font-mono);
  font-size: 10px;
  font-weight: 600;
  color: var(--dash-accent);
  background: color-mix(in srgb, var(--dash-accent) 12%, transparent);
  padding: 1px 7px;
  border-radius: 9999px;
  line-height: 1.6;
}

/* Grids */
.card-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(272px, 1fr)); gap: var(--dash-card-gap, 8px); }
.two-col-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: var(--dash-card-gap, 8px); }
.four-col-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: var(--dash-card-gap, 8px); }

/* Shared card atoms (for inline cards in tabs) */
.card {
  background: var(--fh-bg-panel);
  border-radius: var(--fh-radius-md);
  padding: var(--dash-card-pad, 10px 13px);
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.card-header-row {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 8px;
}
.card-name-mono {
  font-family: var(--fh-font-mono);
  font-size: 12px;
  font-weight: 600;
  color: var(--fh-fg-default);
}
.detail-mono {
  font-family: var(--fh-font-mono);
  font-size: 11px;
  color: var(--fh-fg-subtle);
}
.simple-card {
  background: var(--fh-bg-panel);
  border-radius: var(--fh-radius-md);
  padding: var(--dash-card-pad, 10px 13px);
  display: flex;
  align-items: center;
  gap: 10px;
}
.simple-card-name {
  font-family: var(--fh-font-mono);
  font-size: 12px;
  font-weight: 600;
  color: var(--fh-fg-default);
  flex: 1;
}
.version-pill {
  font-size: 11px;
  font-weight: 600;
  font-family: var(--fh-font-mono);
  padding: 2px 8px;
  border-radius: 9999px;
  background: #12233d;
  color: #9fdff3;
  border: 1px solid #4b8fd1;
  white-space: nowrap;
}
.mono-detail {
  font-family: var(--fh-font-mono);
  font-size: 11px;
  color: var(--fh-fg-subtle);
}

/* Empty state */
.empty { color: var(--fh-fg-subtle); font-size: 13px; font-style: italic; }
.loading-state { color: var(--fh-fg-subtle); font-size: 14px; }
.empty-state {
  padding: 80px 32px;
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 14px;
}
.empty-state-heading {
  font-family: var(--fh-font-display);
  font-size: 22px;
  font-weight: 700;
  color: var(--fh-fg-muted);
  letter-spacing: -0.01em;
}
.empty-state-sub { font-size: 13px; color: var(--fh-fg-subtle); max-width: 300px; line-height: 1.6; }
.empty-state-sub code {
  font-family: var(--fh-font-mono);
  background: var(--fh-bg-panel);
  padding: 1px 5px;
  border-radius: var(--fh-radius-sm);
  font-size: 12px;
}
.empty-state-link {
  color: var(--dash-accent);
  font-size: 14px;
  text-decoration: none;
  margin-top: 4px;
}
.empty-state-link:hover { text-decoration: underline; }

/* Error bar */
.error-bar {
  display: flex;
  align-items: center;
  gap: 8px;
  background: var(--fh-error);
  border: 1px solid var(--fh-error-stroke);
  color: var(--fh-error-fg);
  border-radius: var(--fh-radius-md);
  padding: 10px 14px;
  font-size: 13px;
  margin-bottom: 16px;
}

/* ZSH Profile */
.alias-groups { display: flex; flex-direction: column; gap: 14px; }
.alias-group { display: flex; flex-direction: column; gap: 0; }
.alias-group-title {
  font-size: 11px;
  font-weight: 600;
  color: var(--fh-fg-subtle);
  text-transform: uppercase;
  letter-spacing: 0.08em;
  padding: 6px 10px 5px;
  border-bottom: 1px solid var(--fh-border-subtle);
  background: var(--fh-bg-inset);
  border-radius: var(--fh-radius-md) var(--fh-radius-md) 0 0;
}
.alias-table {
  display: flex;
  flex-direction: column;
  background: var(--fh-bg-panel);
  border: 1px solid var(--fh-border-subtle);
  border-top: none;
  border-radius: 0 0 var(--fh-radius-md) var(--fh-radius-md);
  overflow: hidden;
}
.exports-table {
  border-top: 1px solid var(--fh-border-subtle);
  border-radius: var(--fh-radius-md);
}
.alias-row {
  display: grid;
  grid-template-columns: minmax(100px, 180px) 1fr;
  gap: 12px;
  align-items: baseline;
  padding: 5px 10px;
  transition: background 100ms;
}
.alias-row:hover { background: rgba(255,255,255,0.03); }
.alias-name {
  font-family: var(--fh-font-mono);
  font-size: 12px;
  font-weight: 600;
  color: var(--dash-accent);
  white-space: nowrap;
}
.export-key {
  font-family: var(--fh-font-mono);
  font-size: 11px;
  font-weight: 600;
  color: var(--fh-glacial-cyan);
  white-space: nowrap;
}
.alias-cmd {
  font-family: var(--fh-font-mono);
  font-size: 11.5px;
  color: var(--fh-fg-muted);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.alias-cmd.redacted {
  color: var(--fh-fg-subtle);
  letter-spacing: 0.1em;
}
.fn-desc { font-size: 12px; color: var(--fh-fg-muted); line-height: 1.5; }
.source-badge {
  font-family: var(--fh-font-mono);
  font-size: 10px;
  font-weight: 600;
  color: var(--fh-fg-subtle);
  background: var(--fh-bg-inset);
  border: 1px solid var(--fh-border-subtle);
  padding: 1px 6px;
  border-radius: var(--fh-radius-sm);
  white-space: nowrap;
  flex-shrink: 0;
}

/* Toast */
.toast {
  position: fixed;
  bottom: 20px;
  right: 16px;
  z-index: 200;
  display: flex;
  align-items: center;
  gap: 9px;
  padding: 9px 14px;
  background: var(--fh-bg-panel);
  border: 1px solid var(--fh-border-default);
  border-left: 3px solid var(--dash-accent);
  border-radius: var(--fh-radius-md);
  box-shadow: var(--fh-shadow-md);
  font-size: 12.5px;
  color: var(--fh-fg-default);
  font-family: var(--fh-font-body);
  max-width: 280px;
}
</style>
