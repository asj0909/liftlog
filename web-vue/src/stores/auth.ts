import { defineStore } from 'pinia'
import { computed, ref } from 'vue'
import type { User } from '@supabase/supabase-js'
import { supabase } from '../api/supabase'

// Supabase のエラーを画面に出す日本語メッセージに変換する
function toMessage(error: { code?: string; message: string }): string {
  switch (error.code) {
    case 'invalid_credentials':
      return 'メールアドレスまたはパスワードが違います'
    case 'user_already_exists':
      return 'このメールアドレスは登録済みです'
    case 'weak_password':
      return 'パスワードは 6 文字以上にしてください'
    case 'email_not_confirmed':
      return 'メールアドレスの確認が済んでいません'
    default:
      return '通信に失敗しました。時間をおいて再度お試しください'
  }
}

// ログイン状態をアプリ全体で共有するストア
export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const isLoggedIn = computed(() => user.value !== null)

  // 起動時に 1 回だけ呼ぶ。保存済みのセッションを読み込み、以降の変化を購読する
  let initPromise: Promise<void> | null = null
  function init(): Promise<void> {
    initPromise ??= (async () => {
      const { data } = await supabase.auth.getSession()
      user.value = data.session?.user ?? null
      supabase.auth.onAuthStateChange((_event, session) => {
        user.value = session?.user ?? null
      })
    })()
    return initPromise
  }

  async function signIn(email: string, password: string): Promise<void> {
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) throw new Error(toMessage(error))
  }

  // 戻り値：確認メールが必要なら true
  async function signUp(email: string, password: string): Promise<boolean> {
    const { data, error } = await supabase.auth.signUp({ email, password })
    if (error) throw new Error(toMessage(error))
    return data.session === null
  }

  async function signOut(): Promise<void> {
    await supabase.auth.signOut()
  }

  return { user, isLoggedIn, init, signIn, signUp, signOut }
})
