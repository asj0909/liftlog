# 進捗メモ

新しい会話・セッションを始めるときは、CLAUDE.md とこのファイルを最初に読む。
機能を 1 つ終えるたびに更新する。

最終更新：2026-10-31

## 機能の状況（要件定義書の MVP 範囲）

| 機能 | 画面 | 状態 |
|---|---|---|
| F-01 認証 | S-01 ログイン | 完了 |
| F-03 ワークアウト記録 | S-04 記録 / S-05 種目選択 | 完了（Web・実機で保存を確認） |
| F-04 前回記録の表示 | S-04 | 完了 |
| F-05 履歴（一覧） | S-02 ホーム | 完了 |
| F-06 推移グラフ | S-06 | **未着手**（DB 関数 get_exercise_progress は実装・テスト済み） |
| F-05 履歴（カレンダー） | S-03 | **未着手** |
| F-02 カスタム種目の追加・編集・削除 | S-07 | **未着手**（プリセット 14 種目は利用可能） |
| 設定・ログアウト | S-08 | 完了 |

次にやる順番：S-06 推移グラフ → S-03 カレンダー → S-07 種目管理

## 既知の課題

- セットの ± を素早く連打すると、更新リクエストの応答順が前後して最後の値と違う値が保存される可能性がある（基本設計書 Q-03）
- パスワード再設定メールのリンク先（新しいパスワードを入力する画面）が未実装
- 出荷準備が未着手：アプリ名・アイコン・アプリ ID・Android の署名・Web のホスティング先
- 結合テスト（実際の Supabase に接続して ログイン → 記録 → 履歴 を通す）が未作成
- iOS は手元の Mac（Intel / macOS 13）でビルドできない。確認するなら GitHub Actions の macOS ランナーを使う

## 決定事項（設計書に書いていない細かいもの）

- 履歴一覧の再読み込み：WorkoutController が種目追加・セットの追加・更新・削除に成功するたびに workoutHistoryProvider を invalidate する（「今日の記録」は replace で遷移するため、ホーム側で戻りを await できない）。一覧の表示内容（日付・種目名）に影響するのは種目追加だけなので、通信を減らしたくなったら invalidate を addExercise だけに絞れる
- Supabase のテーブル権限は「新しいテーブルを自動で API に公開」を OFF にし、マイグレーションで GRANT を明示している。テーブルを追加したら GRANT と RLS の両方を忘れないこと
- PostgrestException は code に HTTP ステータス（403 など）、message の JSON に PostgreSQL のコード（42501 など）が入ることがある。supabase_error.dart の postgresErrorCode で JSON 側を優先して取り出す
- debug ビルドではエラー表示（スナックバー・エラー画面）に元の例外も出す。release では出さない

## 開発環境メモ

- 開発は GitHub Codespaces（ローカルの Mac は Intel / macOS 13 で最新 Flutter が動かない）
- Codespaces は 8GB メモリ。APK ビルド前に `flutter run` などを止めないと Gradle が強制終了されることがある（`cd android && ./gradlew --stop` も有効）
- Web の確認：`flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0 --dart-define-from-file=env/dev.json` → ポートタブの 8080 を開く。古いタブを再読み込みすると 401 になることがある
- release ビルドの Android は main の AndroidManifest に INTERNET 権限が必要（追加済み）
- CI：main への push ごとに GitHub Actions で `flutter analyze` と `flutter test` を実行
- env/dev.json（Supabase の URL・キー）は Git に含めない。Codespace を作り直したら手で作る
