import { computed, onMounted, ref } from 'vue'
import * as api from '../api/exerciseApi'
import { CATEGORIES, isPreset, type Exercise, type ExerciseCategory } from '../types/exercise'

// 種目管理画面のロジック（Android の ViewModel にあたる）
export function useExercises() {
  const exercises = ref<Exercise[]>([])
  const loading = ref(true)
  const errorMessage = ref('')

  const presets = computed(() => exercises.value.filter(isPreset))
  const customs = computed(() => exercises.value.filter((e) => !isPreset(e)))

  // カスタム種目を部位ごとにまとめる（種目がない部位は除く）
  const customsByCategory = computed(() =>
    CATEGORIES.map((category) => ({
      category,
      items: customs.value.filter((e) => e.category === category),
    })).filter((group) => group.items.length > 0),
  )

  async function load() {
    loading.value = true
    errorMessage.value = ''
    try {
      exercises.value = await api.fetchExercises()
    } catch (e) {
      errorMessage.value = (e as Error).message
    } finally {
      loading.value = false
    }
  }

  async function add(name: string, category: ExerciseCategory) {
    const created = await api.createExercise(name.trim(), category)
    // 名前順を保ったまま一覧に追加する
    exercises.value = [...exercises.value, created].sort((a, b) => a.name.localeCompare(b.name, 'ja'))
  }

  async function remove(id: string) {
    await api.deleteExercise(id)
    exercises.value = exercises.value.filter((e) => e.id !== id)
  }

  onMounted(load) // 画面が表示されたら読み込む

  return { exercises, presets, customsByCategory, loading, errorMessage, load, add, remove, countUsage: api.countExerciseUsage }
}
