#!/usr/bin/env bash
# Web をデバッグモードで起動する（ホットリロード可：r / R、終了：q）
# 使い方：リポジトリのルートで ./tool/run_web_debug.sh（スクリプト内でルートへ移動するので、別の場所からはパスを指定して実行できる）
# 起動後、Codespaces のポートタブで 8080 を新しいタブで開く（古いタブの再読み込みは 401 になることがある）
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f env/dev.json ]; then
  echo "env/dev.json がありません。env/dev.example.json をコピーして Supabase の URL・キーを設定してください。" >&2
  exit 1
fi

flutter run -d web-server \
  --web-port=8080 \
  --web-hostname=0.0.0.0 \
  --dart-define-from-file=env/dev.json
