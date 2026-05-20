<template>
  <span :style="badgeStyle">
    <span :style="dotStyle" />
    {{ label }}
  </span>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({ status: { type: String, required: true } })

const TONES = {
  ok:            { bg: '#1d3a2a', fg: '#a8e6c0', stroke: '#4ec77a', label: 'ok' },
  'needs-auth':  { bg: '#3a2a12', fg: '#e8c96a', stroke: '#d4a64e', label: 'needs auth' },
  'not-installed': { bg: 'rgba(255,255,255,0.05)', fg: '#a3aab2', stroke: '#6b6355', label: 'not installed' },
  installed:     { bg: '#1d3a2a', fg: '#a8e6c0', stroke: '#4ec77a', label: 'installed' },
  http:          { bg: 'rgba(159,223,243,0.10)', fg: '#9fdff3', stroke: 'rgba(159,223,243,0.30)', label: 'HTTP' },
  sse:           { bg: 'rgba(159,223,243,0.10)', fg: '#9fdff3', stroke: 'rgba(159,223,243,0.30)', label: 'SSE' },
  command:       { bg: 'rgba(159,223,243,0.10)', fg: '#9fdff3', stroke: 'rgba(159,223,243,0.30)', label: 'cmd' },
  unknown:       { bg: 'rgba(255,255,255,0.05)', fg: '#a3aab2', stroke: '#6b6355', label: 'unknown' },
}

const tone = computed(() => TONES[props.status] ?? { bg: 'rgba(255,255,255,0.05)', fg: '#a3aab2', stroke: '#6b6355', label: props.status })
const label = computed(() => tone.value.label)
const badgeStyle = computed(() => ({
  display: 'inline-flex',
  alignItems: 'center',
  gap: '5px',
  padding: '2px 8px',
  borderRadius: '9999px',
  fontSize: '11px',
  fontWeight: '600',
  letterSpacing: '0.03em',
  background: tone.value.bg,
  color: tone.value.fg,
  border: `1px solid ${tone.value.stroke}`,
  whiteSpace: 'nowrap',
  flexShrink: '0',
}))
const dotStyle = computed(() => ({
  width: '5px',
  height: '5px',
  borderRadius: '50%',
  background: tone.value.stroke,
  flexShrink: '0',
}))
</script>
