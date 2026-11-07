<script setup lang="ts">
import { ref } from 'vue'
import { useExercises } from '../composables/useExercises'
import {
  CATEGORIES,
  CATEGORY_LABELS,
  EXERCISE_NAME_MAX_LENGTH,
  validateExerciseName,
  type Exercise,
  type ExerciseCategory,
} from '../types/exercise'

const { exercises, presets, customsByCategory, loading, errorMessage, load, add, remove, countUsage } =
  useExercises()

// 追加フォームの入力値
const newName = ref('')
const newCategory = ref<ExerciseCategory>('chest')
const formError = ref('')
const saving = ref(false)

async function submit() {
  formError.value = validateExerciseName(newName.value, exercises.value) ?? ''
  if (formError.value) return

  saving.value = true
  try {
    await add(newName.value, newCategory.value)
    newName.value = '' // 成功したら入力欄を空にする
  } catch (e) {
    formError.value = (e as Error).message
  } finally {
    saving.value = false
  }
}

async function confirmDelete(target: Exercise) {
  try {
    const usage = await countUsage(target.id)
    const detail =
      usage === 0
        ? 'この種目は記録で使われていません。'
        : `この種目は ${usage} 件の記録で使われています。削除すると、その記録（セット）もすべて削除され、元に戻せません。`
    // ブラウザ標準の確認ダイアログ（OK で true）
    if (!window.confirm(`「${target.name}」を削除しますか？\n${detail}`)) return
    await remove(target.id)
  } catch (e) {
    window.alert((e as Error).message)
  }
}
</script>

<template>
  <main class="page">
    <RouterLink to="/">← ホーム</RouterLink>
    <h1>種目管理</h1>

    <!-- 追加フォーム -->
    <form class="add-form" @submit.prevent="submit">
      <input v-model="newName" placeholder="種目名" :maxlength="EXERCISE_NAME_MAX_LENGTH">
      <select v-model="newCategory">
        <option v-for="c in CATEGORIES" :key="c" :value="c">{{ CATEGORY_LABELS[c] }}</option>
      </select>
      <button type="submit" :disabled="saving">追加</button>
    </form>
    <p v-if="formError" class="error">{{ formError }}</p>

    <!-- 読み込み中 / エラー / 一覧 -->
    <p v-if="loading">読み込み中…</p>
    <div v-else-if="errorMessage">
      <p class="error">{{ errorMessage }}</p>
      <button @click="load">再読み込み</button>
    </div>
    <template v-else>
      <h2>カスタム種目</h2>
      <p v-if="customsByCategory.length === 0" class="muted">
        カスタム種目はまだありません。上のフォームから登録できます。
      </p>
      <section v-for="group in customsByCategory" :key="group.category">
        <h3>{{ CATEGORY_LABELS[group.category] }}</h3>
        <ul>
          <li v-for="e in group.items" :key="e.id">
            <span>{{ e.name }}</span>
            <button class="delete" @click="confirmDelete(e)">削除</button>
          </li>
        </ul>
      </section>

      <!-- <details> はクリックで開閉できる HTML 標準の要素 -->
      <details>
        <summary>プリセット種目（{{ presets.length }}）</summary>
        <p class="muted">プリセットは編集・削除できません</p>
        <ul>
          <li v-for="e in presets" :key="e.id">
            <span>{{ e.name }}</span>
            <span class="muted">{{ CATEGORY_LABELS[e.category] }}</span>
          </li>
        </ul>
      </details>
    </template>
  </main>
</template>

<style scoped>
.page { max-width: 640px; margin: 0 auto; padding: 24px; }
.add-form { display: flex; gap: 8px; }
.add-form input { flex: 1; padding: 8px; font-size: 16px; }
.add-form select, .add-form button { padding: 8px; font-size: 16px; }
ul { list-style: none; padding: 0; margin: 0; }
li { display: flex; justify-content: space-between; align-items: center; padding: 8px 0; border-bottom: 1px solid #eee; }
h3 { margin: 16px 0 4px; font-size: 14px; color: #555; }
details { margin-top: 24px; }
summary { cursor: pointer; font-weight: bold; }
.delete { color: #c62828; background: none; border: 1px solid #c62828; border-radius: 4px; cursor: pointer; }
.error { color: #c62828; }
.muted { color: #888; font-size: 14px; }
</style>
