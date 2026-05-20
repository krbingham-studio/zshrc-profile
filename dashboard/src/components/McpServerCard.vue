<template>
  <div class="card dash-card">
    <div class="card-header">
      <span class="card-name">{{ server.name }}</span>
      <StatusBadge :status="server.authStatus" />
    </div>
    <div class="card-type">
      <span class="type-badge">{{ server.type }}</span>
      <span v-if="showSource && server.source" class="source-badge">{{ server.source }}</span>
    </div>
    <div
      v-if="server.url || server.command"
      class="detail-row"
      :class="{ copied }"
      :title="server.url || server.command"
      @click="handleCopy"
    >{{ server.url || server.command }}</div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import StatusBadge from './StatusBadge.vue'

const props = defineProps({
  server: { type: Object, required: true },
  showSource: { type: Boolean, default: false },
})
const copied = ref(false)

function handleCopy() {
  const text = props.server.url || props.server.command
  if (!text) return
  navigator.clipboard.writeText(text).then(() => {
    copied.value = true
    setTimeout(() => { copied.value = false }, 1500)
    window.dispatchEvent(new CustomEvent('dash-toast', { detail: { msg: `Copied: ${props.server.name}`, icon: 'copy' } }))
  })
}
</script>

<style scoped>
.card {
  background: var(--fh-bg-panel);
  border-radius: var(--fh-radius-md);
  padding: var(--dash-card-pad, 10px 13px);
  display: flex;
  flex-direction: column;
  gap: 9px;
}
.card-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 8px;
}
.card-name {
  font-family: var(--fh-font-mono);
  font-size: 12px;
  font-weight: 600;
  color: var(--fh-fg-default);
  line-height: 1.3;
}
.card-type { display: flex; align-items: center; gap: 8px; }
.type-badge {
  display: inline-flex;
  align-items: center;
  padding: 1px 6px;
  border-radius: var(--fh-radius-sm);
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.07em;
  text-transform: uppercase;
  font-family: var(--fh-font-mono);
  background: rgba(159,223,243,0.10);
  color: #9fdff3;
  border: 1px solid rgba(159,223,243,0.20);
  white-space: nowrap;
}
.detail-row {
  font-family: var(--fh-font-mono);
  font-size: 10.5px;
  color: var(--fh-fg-muted);
  background: var(--fh-bg-inset);
  padding: 5px 8px;
  border-radius: var(--fh-radius-sm);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  cursor: pointer;
  outline: 1px solid transparent;
  transition: color 150ms, outline-color 150ms;
  user-select: none;
}
.detail-row:hover { color: var(--fh-fg-default); }
.detail-row.copied { color: var(--dash-accent); outline-color: var(--dash-accent); }
</style>
