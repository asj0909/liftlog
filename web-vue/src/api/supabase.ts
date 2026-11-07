import { createClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL
const key = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY

if (!url || !key) {
  throw new Error('.env.local に VITE_SUPABASE_URL と VITE_SUPABASE_PUBLISHABLE_KEY を設定してください')
}

// アプリ全体で 1 つだけ使う Supabase クライアント
export const supabase = createClient(url, key)
