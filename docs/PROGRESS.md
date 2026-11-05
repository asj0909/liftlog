# 進捗メモ

新しい会話・セッションを始めるときは、CLAUDE.md とこのファイルを最初に読む。
機能を 1 つ終えるたびに更新する。

最終更新：2026-11-04

## 機能の状況（要件定義書の MVP 範囲）

| 機能 | 画面 | 状態 |
|---|---|---|
| F-01 認証 | S-01 ログイン | 完了 |
| F-03 ワークアウト記録 | S-04 記録 / S-05 種目選択 | 完了（Web・実機で保存を確認） |
| F-04 前回記録の表示 | S-04 | 完了 |
| F-05 履歴（一覧） | S-02 ホーム | 完了 |
| F-06 推移グラフ | S-06 | 完了（ウィジェットテストまで。実機・Web での表示確認は未） |
| F-05 履歴（カレンダー） | S-03 | 完了（ウィジェットテストまで。実機・Web での表示確認は未） |
| F-02 カスタム種目の追加・編集・削除 | S-07 | 完了（ウィジェットテストまで。実機・Web での表示確認は未） |
| 設定・ログアウト | S-08 | 完了 |

MVP の画面はすべて実装済み。Google Play への公開準備中（下の「Play ストア公開」）

## 既知の課題

- 出荷準備の残り：アイコン、プライバシーポリシーとアカウント削除案内の Web ページ、Web のホスティング先
- 結合テスト（実際の Supabase に接続して ログイン → 記録 → 履歴 を通す）が未作成
- iOS は手元の Mac（Intel / macOS 13）でビルドできない。確認するなら GitHub Actions の macOS ランナーを使う

## 決定事項（設計書に書いていない細かいもの）

- 履歴一覧の再読み込み：WorkoutController が種目追加・セットの追加・更新・削除に成功するたびに workoutHistoryProvider を invalidate する（「今日の記録」は replace で遷移するため、ホーム側で戻りを await できない）。一覧の表示内容（日付・種目名）に影響するのは種目追加だけなので、通信を減らしたくなったら invalidate を addExercise だけに絞れる
- Supabase のテーブル権限は「新しいテーブルを自動で API に公開」を OFF にし、マイグレーションで GRANT を明示している。テーブルを追加したら GRANT と RLS の両方を忘れないこと
- PostgrestException は code に HTTP ステータス（403 など）、message の JSON に PostgreSQL のコード（42501 など）が入ることがある。supabase_error.dart の postgresErrorCode で JSON 側を優先して取り出す
- 推移グラフ：種目・期間は URL（`/progress?exercise=&range=`）が正で、変更は `context.go` で URL を書き換える。指標（コンパクト時の切り替え）は画面内の状態で URL には入れない
- 推移グラフの期間の起点は「今日」（`todayProvider`）。月末は移動先の月末に丸める（3/31 の 1 か月前は 2/28）
- 推移グラフの横軸は最初の実施日からの日数（実施間隔が空いた分だけ点も離れる）。ミディアム幅は 3 指標を 1 列、エキスパンデッドは 2 列で表示
- WorkoutController は保存成功時に workoutHistoryProvider に加えて exerciseProgressProvider（family 全体）も invalidate する
- 種目選択は全種目（プリセット＋カスタム）を出す。記録のない種目を選ぶと「記録が 2 回以上になると〜」の案内になる。URL の種目 id が一覧にない場合は未選択表示
- カレンダー：データは S-02 と同じ workoutHistoryProvider（種目 0 件の日は実施日にしない）。日付を選ぶと下（ミディアム以上は右）にその日の記録を出し、なければ「この日の記録を作成」で `/workouts/new?date=` を開く。未来の日は選べない
- カレンダーは table_calendar の locale を指定せず、見出し（2026年11月）・曜日は formatter で日本語にしている（intl の日本語データ初期化を不要にするため）
- 「今日」は core/date の `todayProvider` で注入する（推移グラフとカレンダーで共用。テストで日付を固定するため）
- 種目管理：カスタム種目の名前は前後の空白を除いて保存し、プリセット・自分の種目と同じ名前は画面側で禁止する（DB の一意制約はユーザー内だけで、プリセットと同名は通ってしまうため）
- 種目の削除は常に確認ダイアログを出す。記録で使われていれば件数と「記録（セット）も削除され元に戻せない」ことを表示する（削除は DB の ON DELETE CASCADE）
- 種目の追加・編集・削除に成功したら exercisesProvider を invalidate（S-05 にも反映）。編集・削除は履歴一覧と推移グラフも invalidate する（種目名・記録が変わるため）
- exercises.user_id には既定値がない（NULL＝プリセット）ので、追加時はクライアントが auth の user id を入れる。他人の id は RLS で拒否される
- debug ビルドではエラー表示（スナックバー・エラー画面）に元の例外も出す。release では出さない

## Play ストア公開

- アプリ ID：`com.oojimarounin.liftlog`（公開後は変更不可）。表示名はホーム画面「LiftLog」、ストアの掲載名「LiftLog - 筋トレ記録」
- バージョンは pubspec.yaml の `version: 1.0.0+1`。ストアに上げるたびに + の後ろ（versionCode）を増やす
- 署名：アップロード鍵（`./tool/create_upload_key.sh` で作成、既定 `~/keys/liftlog-upload.jks`）＋ Play アプリ署名。鍵とパスワードは Codespace の外にバックアップする。`android/key.properties` がないと release は debug 署名になる（ストア提出不可）
- 提出物：`./tool/build_release_aab.sh` → `build/app/outputs/bundle/release/app-release.aab`。接続先は本番の Supabase（`env/prod.json`）
- 本番の Supabase は開発用と別プロジェクト（LiftLog-prod）。Codespace に Supabase CLI がないため、マイグレーションと seed.sql はダッシュボードの SQL Editor で古い順に実行して適用する（マイグレーションを追加したら本番にも同じ手順で適用すること）
- アカウント削除：設定画面の「アカウントを削除」→ DB 関数 `delete_my_account()`（SECURITY DEFINER。auth.users から本人を消し、記録は CASCADE で消える）。Play の要件で Web からの削除依頼窓口（URL）も必要。応答を受け取れず削除できたか分からないとき（通信断・5xx・成功応答の本文が読めない）は端末のセッションを破棄して「確認できなかった」と表示する。サーバーが失敗を返したとき（PostgreSQL のコード・PGRST・4xx）と送信前のトークン更新の失敗はログインしたまま
- パスワード再設定：メールのリンクは GitHub Pages の `site/reset-password.html`（フラグメントの token_hash を、「変更する」を押したときに verifyOtp で確認 → updateUser。開いただけではトークンを使わない）。アプリは PKCE なので、Supabase の既定のリンク（?code=）は Web では使えない。そのため Supabase のメールテンプレートを token_hash 方式に変えている（設定は docs/03_ストア掲載情報.md の「Supabase の認証設定」）。接続先は `site/supabase-config.js`（publishable キーのみ）
- アプリ内のプライバシーポリシー：ログイン画面の下と設定画面にリンク（Play のユーザーデータ ポリシーで必須）。URL は core/links/external_links.dart、開くのは url_launcher（openUrlProvider でテスト時に差し替え）
- 新しい個人デベロッパーアカウントは、製品版の前にクローズドテスト（テスター 12 人以上 × 14 日間連続）が必要

## 開発環境メモ

- 開発は GitHub Codespaces（ローカルの Mac は Intel / macOS 13 で最新 Flutter が動かない）
- Codespaces は 8GB メモリ。APK ビルド前に `flutter run` などを止めないと Gradle が強制終了されることがある（`cd android && ./gradlew --stop` も有効）
- Web の確認：`./tool/run_web_debug.sh`（debug・ホットリロード可）→ ポートタブの 8080 を新しいタブで開く。古いタブを再読み込みすると 401 や読み込み中のままになることがある
- debug が読み込み中のまま止まるときは、debug のターミナルで `q` を押して終了してから `./tool/run_web_release.sh`（release ビルド＋静的サーバー dhttpd。同じ 8080 番を使う。コードを変えたら再実行）
- release ビルドの Android は main の AndroidManifest に INTERNET 権限が必要（追加済み）
- CI：main への push と PR ごとに GitHub Actions で `flutter analyze`・`flutter test`（test ジョブ）と `flutter build apk --release`（android ジョブ。key.properties がないので debug 署名）を実行。アクションはコミット SHA で固定
- env/dev.json（Supabase の URL・キー）は Git に含めない。Codespace を作り直したら手で作る
