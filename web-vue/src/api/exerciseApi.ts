import { supabase } from './supabase'
import type { Exercise, ExerciseCategory } from '../types/exercise'

// DB の行（スネークケース）
interface ExerciseRow {
  id: string
  user_id: string | null
  name: string
  category: ExerciseCategory
}

const COLUMNS = 'id, user_id, name, category'

// DB の行 → アプリのモデルに変換
const toExercise = (row: ExerciseRow): Exercise => ({
  id: row.id,
  name: row.name,
  category: row.category,
  userId: row.user_id,
})

// Supabase のエラーを日本語メッセージの Error に変換する
function fail(): never {
  throw new Error('通信に失敗しました。時間をおいて再度お試しください')
}

// RLS により、プリセットと自分の種目だけが返る
export async function fetchExercises(): Promise<Exercise[]> {
  const { data, error } = await supabase.from('exercises').select(COLUMNS).order('name')
  if (error) fail()
  return (data as ExerciseRow[]).map(toExercise)
}

export async function createExercise(name: string, category: ExerciseCategory): Promise<Exercise> {
  // user_id には既定値がない（null はプリセットを表す）ので明示する
  const { data: auth } = await supabase.auth.getUser()
  if (!auth.user) throw new Error('ログインし直してください')

  const { data, error } = await supabase
    .from('exercises')
    .insert({ user_id: auth.user.id, name, category })
    .select(COLUMNS)
    .single()
  if (error) fail()
  return toExercise(data as ExerciseRow)
}

// workout_exercises・sets は ON DELETE CASCADE で一緒に消える
export async function deleteExercise(id: string): Promise<void> {
  const { error } = await supabase.from('exercises').delete().eq('id', id)
  if (error) fail()
}

// その種目が何件の記録で使われているか（削除確認に使う）
export async function countExerciseUsage(id: string): Promise<number> {
  const { count, error } = await supabase
    .from('workout_exercises')
    .select('id', { count: 'exact', head: true })
    .eq('exercise_id', id)
  if (error) fail()
  return count ?? 0
}
