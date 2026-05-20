<template>
  <div class="card dash-card">
    <div class="card-header">
      <span class="card-name">{{ plugin.name }}</span>
      <span class="version-badge" v-if="plugin.version">v{{ plugin.version }}</span>
    </div>
    <div class="card-footer" v-if="plugin.updatedAt">
      <iconify-icon icon="lucide:clock" width="11" height="11" class="clock-icon" />
      updated {{ formatDate(plugin.updatedAt) }}
    </div>
  </div>
</template>

<script setup>
defineProps({ plugin: { type: Object, required: true } })

function formatDate(iso) {
  if (!iso) return ''
  return new Date(iso).toLocaleDateString(undefined, { month: 'short', day: 'numeric', year: 'numeric' })
}
</script>

<style scoped>
.card {
  background: var(--fh-bg-panel);
  border-radius: var(--fh-radius-md);
  padding: var(--dash-card-pad, 10px 13px);
  display: flex;
  flex-direction: column;
  gap: 8px;
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
  line-height: 1.4;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  min-width: 0;
}
.version-badge {
  display: inline-flex;
  align-items: center;
  padding: 2px 8px;
  border-radius: 9999px;
  font-size: 11px;
  font-weight: 600;
  background: #12233d;
  color: #9fdff3;
  border: 1px solid #4b8fd1;
  white-space: nowrap;
  flex-shrink: 0;
}
.card-footer {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 11px;
  color: var(--fh-fg-subtle);
}
.clock-icon { color: var(--fh-fg-subtle); flex-shrink: 0; }
</style>
