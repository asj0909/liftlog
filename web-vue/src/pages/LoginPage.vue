<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const auth = useAuthStore()
const router = useRouter()

const email = ref('')
const password = ref('')
const isSignUp = ref(false)      // true：新規登録モード / false：ログインモード
const loading = ref(false)
const errorMessage = ref('')
const infoMessage = ref('')

async function submit() {
  errorMessage.value = ''
  infoMessage.value = ''
  loading.value = true
  try {
    if (isSignUp.value) {
      const needsConfirm = await auth.signUp(email.value, password.value)
      if (needsConfirm) {
        infoMessage.value = '確認メールを送信しました。メール内のリンクを開いてからログインしてください'
        isSignUp.value = false
        return
      }
    } else {
      await auth.signIn(email.value, password.value)
    }
    await router.push({ name: 'home' })
  } catch (e) {
    errorMessage.value = (e as Error).message
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <main class="login">
    <h1>LiftLog</h1>

    <form @submit.prevent="submit">
      <label>
        メールアドレス
        <input v-model="email" type="email" autocomplete="email" required>
      </label>
      <label>
        パスワード
        <input v-model="password" type="password" minlength="6" required
               :autocomplete="isSignUp ? 'new-password' : 'current-password'">
      </label>

      <p v-if="errorMessage" class="error">{{ errorMessage }}</p>
      <p v-if="infoMessage" class="info">{{ infoMessage }}</p>

      <button type="submit" :disabled="loading">
        {{ loading ? '処理中…' : isSignUp ? '新規登録' : 'ログイン' }}
      </button>
    </form>

    <button class="link" type="button" @click="isSignUp = !isSignUp">
      {{ isSignUp ? 'アカウントをお持ちの方はこちら' : 'アカウントを作成する' }}
    </button>
  </main>
</template>

<style scoped>
.login { max-width: 360px; margin: 64px auto; padding: 0 16px; }
form { display: flex; flex-direction: column; gap: 16px; }
label { display: flex; flex-direction: column; gap: 4px; font-size: 14px; }
input { padding: 10px; font-size: 16px; border: 1px solid #ccc; border-radius: 6px; }
button[type='submit'] { padding: 12px; font-size: 16px; border: none; border-radius: 6px; background: #1e6fd9; color: #fff; cursor: pointer; }
button[type='submit']:disabled { opacity: 0.6; }
.link { margin-top: 16px; background: none; border: none; color: #1e6fd9; cursor: pointer; }
.error { color: #c62828; margin: 0; }
.info { color: #2e7d32; margin: 0; }
</style>
