<template>
  <div class="card dash-card">
    <div class="card-header" @click="expanded = !expanded">
      <div class="card-body">
        <div class="card-name">{{ skill.name }}</div>
        <div class="card-desc" v-if="skill.description">{{ skill.description }}</div>
      </div>
      <span v-if="skill.body" class="chevron" :class="{ open: expanded }">
        <iconify-icon icon="lucide:chevron-down" width="14" height="14" />
      </span>
    </div>
    <div v-if="expanded && skill.body" class="expanded-body">{{ skill.body }}</div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
defineProps({ skill: { type: Object, required: true } })
const expanded = ref(false)
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
