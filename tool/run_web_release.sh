#!/usr/bin/env bash
# Web を release ビルドして静的サーバーで配信する（Codespaces で debug が読み込み中のまま止まるときに使う）
# 使い方：リポジトリのどこからでも ./tool/run_web_release.sh
# コードを変えたら Ctrl + C で止めて、もう一度実行する（毎回ビルドし直す）
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f env/dev.json ]; then
  echo "env/dev.json がありません。env/dev.example.json をコピーして Supabase の URL・キーを設定してください。" >&2
  exit 1
fi

flutter build web --dart-define-from-file=env/dev.json

# 静的サーバー dhttpd は初回だけ入れる
if ! dart pub global list | grep -q '^dhttpd '; then
  dart pub global activate dhttpd
fi

echo "==> http://0.0.0.0:8080 で配信します（ポートタブで 8080 を開く。停止は Ctrl + C）"
dart pub global run dhttpd --path build/web --host 0.0.0.0 --port 8080
