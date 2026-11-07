<script setup lang="ts">
import { ref } from 'vue'

const count = ref(0)
</script>

<template>
  <main>
    <h1>LiftLog</h1>
    <p>Vue 版の準備ができました</p>
    <button @click="count++">押した回数：{{ count }}</button>
  </main>
</template>

<style scoped>
main {
  max-width: 640px;
  margin: 0 auto;
  padding: 24px;
}
</style>
