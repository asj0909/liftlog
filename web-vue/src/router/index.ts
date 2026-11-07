import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import LoginPage from '../pages/LoginPage.vue'
import HomePage from '../pages/HomePage.vue'
import ExerciseManagePage from '../pages/ExerciseManagePage.vue'

export const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/login', name: 'login', component: LoginPage, meta: { public: true } },
    { path: '/', name: 'home', component: HomePage },
    { path: '/settings/exercises', name: 'exercises', component: ExerciseManagePage },
  ],
})

// 画面遷移の前に毎回呼ばれる（ルートガード）
router.beforeEach(async (to) => {
  const auth = useAuthStore()
  await auth.init()

  // 未ログインでログイン必須の画面 → ログイン画面へ
  if (!auth.isLoggedIn && !to.meta.public) {
    return { name: 'login' }
  }
  // ログイン済みでログイン画面 → ホームへ
  if (auth.isLoggedIn && to.name === 'login') {
    return { name: 'home' }
  }
})
