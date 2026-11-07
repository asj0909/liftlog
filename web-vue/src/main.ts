import { createApp } from 'vue'
import { createPinia } from 'pinia'
import './style.css'
import App from './App.vue'
import { router } from './router'

createApp(App)
  .use(createPinia()) // 状態管理（Pinia）を有効にする
  .use(router)        // 画面遷移（Vue Router）を有効にする
  .mount('#app')
