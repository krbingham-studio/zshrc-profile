<template>
  <div class="skill-list">
    <span
      v-for="item in items"
      :key="item"
      class="tag"
      @mouseenter="hovered = item"
      @mouseleave="hovered = null"
      :class="{ active: hovered === item }"
    >{{ item }}</span>
    <span v-if="!items.length" class="empty">None found</span>
  </div>
</template>

<script setup>
import { ref } from 'vue'
defineProps({ items: { type: Array, default: () => [] } })
const hovered = ref(null)
</script>

<style scoped>
.skill-list { display: flex; flex-wrap: wrap; gap: 6px; }
.tag {
  display: inline-flex;
  align-items: center;
  padding: 3px 9px;
  border-radius: 9999px;
  font-size: 11.5px;
  font-weight: 500;
  font-family: var(--fh-font-mono);
  background: rgba(255,255,255,0.04);
  color: var(--fh-fg-muted);
  border: 1px solid var(--fh-border-subtle);
  cursor: default;
  transition: all 120ms;
  user-select: none;
}
.tag.active {
  background: color-mix(in srgb, var(--dash-accent) 10%, transparent);
  color: var(--dash-accent);
  border-color: var(--dash-accent);
}
.empty { color: var(--fh-fg-subtle); font-size: 13px; font-style: italic; }
</style>
