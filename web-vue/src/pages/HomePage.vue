<script setup lang="ts">
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const auth = useAuthStore()
const router = useRouter()

async function logout() {
  await auth.signOut()
  await router.push({ name: 'login' })
}
</script>

<template>
  <main class="home">
    <h1>ホーム</h1>
    <p>{{ auth.user?.email }} でログイン中</p>
    <p><RouterLink :to="{ name: 'exercises' }">種目管理</RouterLink></p>
    <button @click="logout">ログアウト</button>
  </main>
</template>

<style scoped>
.home { max-width: 640px; margin: 0 auto; padding: 24px; }
</style>
