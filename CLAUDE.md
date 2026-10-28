# LiftLog — Claude 向けプロジェクトガイド

## 概要
Flutter（Android / iOS / Web）＋ Supabase の筋トレ記録アプリ。
仕様は docs/01_要件定義書.md、設計は docs/02_基本設計書.md を正とする。

## コマンド
- 解析：`flutter analyze`
- テスト：`flutter test`
- DB テスト：`supabase test db`
- DB 再構築：`supabase db reset`
- 起動：`flutter run -d chrome --dart-define-from-file=env/dev.json`

## アーキテクチャのルール
- `lib/features/<機能>/` の中を `data / domain / application / presentation` に分ける
- `domain` は純粋な Dart。Flutter・Supabase を import しない
- Supabase の例外は data レイヤーで `AppException`（core/error）に変換する
- Repository は抽象を domain に置き、実装を data に置く。Provider 経由で注入し、テストではフェイクに差し替える
- 状態管理は Riverpod（コード生成なし）。画面状態は `AsyncNotifier` ＋ `AsyncValue`
- 画面幅の判定は `WindowSize.fromWidth`（core/layout）を使い、数値を直書きしない

## DB のルール
- スキーマ変更は `supabase/migrations/` に新しいファイルを追加する（既存ファイルは編集しない）
- 新しいテーブルには必ず RLS と `user_id`、所有者チェックを付け、pgTAP テストを追加する
- 推定 1RM の計算式は `TrainingMetrics.estimateOneRepMax` と `public.estimate_one_rep_max` で同一に保つ

## 書き方
- UI 文言・コメント・設計書は日本語
- 機能を追加したら、対応する単体テスト／ウィジェットテストも同じ変更で追加する
