// 種目のモデル（Flutter 版 domain/exercise.dart と同じ内容）

// 部位カテゴリ。exercises.category の CHECK 制約と一致させる
export type ExerciseCategory = 'chest' | 'back' | 'legs' | 'shoulders' | 'arms' | 'core' | 'other'

export const CATEGORY_LABELS: Record<ExerciseCategory, string> = {
  chest: '胸',
  back: '背中',
  legs: '脚',
  shoulders: '肩',
  arms: '腕',
  core: '体幹',
  other: 'その他',
}

// 画面に並べる順番
export const CATEGORIES = Object.keys(CATEGORY_LABELS) as ExerciseCategory[]

export interface Exercise {
  id: string
  name: string
  category: ExerciseCategory
  userId: string | null // null ならプリセット
}

export const isPreset = (e: Exercise): boolean => e.userId === null

export const EXERCISE_NAME_MAX_LENGTH = 50

// 種目名の入力チェック。問題なければ null を返す
export function validateExerciseName(value: string, existing: Exercise[]): string | null {
  const name = value.trim()
  if (name === '') return '種目名を入力してください'
  if (name.length > EXERCISE_NAME_MAX_LENGTH) {
    return `種目名は${EXERCISE_NAME_MAX_LENGTH}文字以内で入力してください`
  }
  const same = existing.find((e) => e.name === name)
  if (same) {
    return isPreset(same) ? '同じ名前のプリセット種目があります' : '同じ名前の種目がすでに登録されています'
  }
  return null
}
