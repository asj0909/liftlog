# LiftLog

筋トレ記録アプリ。スマホでセットを記録し、Web の広い画面で成長の推移を確認する。
Flutter（Android / iOS / Web）＋ Supabase。

- 要件定義書：[docs/01_要件定義書.md](docs/01_要件定義書.md)
- 基本設計書：[docs/02_基本設計書.md](docs/02_基本設計書.md)

## 必要なもの

- Flutter（stable）
- Docker（ローカル Supabase 用）
- Supabase CLI（`brew install supabase/tap/supabase`）

## セットアップ

```bash
# 1. ローカル Supabase を起動（初回のみ init）
supabase init          # 既存の supabase/ フォルダはそのまま使われる
supabase start         # 表示される API URL と anon key を控える
supabase db reset      # migrations と seed.sql を適用

# 2. Flutter プロジェクトの初期化・パッケージ追加・解析・テスト
bash tool/setup.sh

# 3. env/dev.json に Supabase の URL と anon key を設定して起動
flutter run -d chrome --dart-define-from-file=env/dev.json
```

## GitHub Codespaces で開発する場合

ローカルに Flutter を入れられない環境（古い Mac など）向け。

1. GitHub のリポジトリ画面で **Code → Codespaces → Create codespace on main**
2. 初回は Flutter の取得と `tool/setup.sh` が自動で走る（数分）
3. Supabase はクラウド版を使う。`env/dev.json` に Project URL と anon key を設定
4. 起動（Chrome がないため Web サーバーとして起動し、転送されたポートをブラウザで開く）

```bash
flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0 \
  --dart-define-from-file=env/dev.json
```

### Codespaces で APK をビルドして実機で確認する

Codespaces ではエミュレーターが動かないため、APK を作って実機にインストールする。

```bash
bash tool/setup-android-sdk.sh                              # 初回のみ（約 10 分）
flutter build apk --dart-define-from-file=env/dev.json      # build/app/outputs/flutter-apk/app-release.apk
```

## テスト

```bash
flutter test           # 単体・ウィジェットテスト
supabase test db       # DB テスト（RLS・集計関数）
```

## ディレクトリ構成

```
lib/
├── app/          # ルーティング・テーマ・環境変数
├── core/         # エラー・レイアウト・Supabase など共通部品
└── features/     # 機能ごとに data / domain / application / presentation
supabase/
├── migrations/   # テーブル・RLS・DB 関数
├── tests/        # pgTAP
└── seed.sql      # プリセット種目
docs/             # 設計書
```
