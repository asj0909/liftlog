#!/usr/bin/env bash
# LiftLog 初回セットアップ
# リポジトリのルートで実行する: bash tool/setup.sh
set -euo pipefail

cd "$(dirname "$0")/.."

echo "==> プラットフォームフォルダを生成（既存ファイルは上書きしない）"
flutter create --project-name liftlog --org com.liftlog \
  --platforms android,ios,web .

echo "==> 依存パッケージを追加"
flutter pub add flutter_riverpod go_router supabase_flutter fl_chart table_calendar intl
flutter pub add 'flutter_localizations:{"sdk":"flutter"}'
flutter pub add --dev mocktail flutter_lints

echo "==> flutter create が生成したサンプルテストを削除"
rm -f test/widget_test.dart

echo "==> 環境変数ファイルを用意"
if [ ! -f env/dev.json ]; then
  cp env/dev.example.json env/dev.json
  echo "    env/dev.json を作成しました。Supabase の URL と anon key を設定してください。"
fi

echo "==> 静的解析とテスト"
flutter analyze --no-fatal-infos
flutter test

echo "完了。起動: flutter run -d chrome --dart-define-from-file=env/dev.json"
