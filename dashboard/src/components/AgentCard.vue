<template>
  <div class="card dash-card">
    <div class="card-header" @click="expanded = !expanded">
      <div class="card-body">
        <div class="card-name">{{ agent.name }}</div>
        <div class="card-desc" v-if="agent.description">{{ agent.description }}</div>
      </div>
      <button
        class="run-btn"
        @click.stop="handleRun"
      >Run</button>
      <span class="chevron" :class="{ open: expanded }">
        <iconify-icon icon="lucide:chevron-down" width="14" height="14" />
      </span>
    </div>
    <div v-if="expanded && agent.body" class="expanded-body">{{ agent.body }}</div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const props = defineProps({ agent: { type: Object, required: true } })
const expanded = ref(false)

function handleRun() {
  window.dispatchEvent(new CustomEvent('dash-toast', {
    detail: { msg: `Running ${props.agent.name}…`, icon: 'play' }
  }))
}
</script>

<style scoped>
.card {
  background: var(--fh-bg-panel);
  border-radius: var(--fh-radius-md);
  overflow: hidden;
}
.card-header {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  padding: var(--dash-card-pad, 10px 13px);
  cursor: pointer;
}
.card-body { flex: 1; min-width: 0; }
.card-name {
  font-family: var(--fh-font-mono);
  font-size: 12.5px;
  font-weight: 600;
  color: var(--fh-fg-default);
  margin-bottom: 4px;
}
.card-desc {
  font-size: 12px;
  color: var(--fh-fg-muted);
  line-height: 1.55;
}
.run-btn {
  flex-shrink: 0;
  padding: 3px 9px;
  font-size: 11px;
  font-weight: 600;
  font-family: var(--fh-font-body);
  background: color-mix(in srgb, var(--dash-accent) 12%, transparent);
  color: var(--dash-accent);
  border: 1px solid color-mix(in srgb, var(--dash-accent) 35%, transparent);
  border-radius: var(--fh-radius-md);
  cursor: pointer;
  transition: background 120ms;
}
.run-btn:hover {
  background: color-mix(in srgb, var(--dash-accent) 22%, transparent);
}
.chevron {
  flex-shrink: 0;
  display: inline-flex;
  margin-top: 2px;
  color: var(--dash-accent);
  transition: transform 200ms ease;
}
.chevron.open { transform: rotate(180deg); }
.expanded-body {
  background: var(--fh-bg-inset);
  border-top: 1px solid var(--fh-border-subtle);
  padding: 12px 16px;
  font-family: var(--fh-font-mono);
  font-size: 11px;
  line-height: 1.8;
  color: var(--fh-fg-muted);
  white-space: pre-wrap;
  word-break: break-word;
  overflow-x: auto;
}
</style>
