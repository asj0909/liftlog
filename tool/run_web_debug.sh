#!/usr/bin/env bash
# Web をデバッグモードで起動する（ホットリロード可：r / R、終了：q）
# 使い方：リポジトリのルートで ./tool/run_web_debug.sh [dev|prod]（スクリプト内でルートへ移動するので、別の場所からはパスを指定して実行できる）
# 起動後、Codespaces のポートタブで 8080 を新しいタブで開く（古いタブの再読み込みは 401 になることがある）
set -euo pipefail
cd "$(dirname "$0")/.."

# 接続先：引数で dev（既定）/ prod を選ぶ。prod は本番の Supabase（実際の利用者のデータ）に接続する
ENV_NAME="${1:-dev}"
case "$ENV_NAME" in
  dev|prod) ;;
  *) echo "使い方: $0 [dev|prod]（既定は dev）" >&2; exit 1 ;;
esac
ENV_FILE="env/$ENV_NAME.json"
if [ ! -f "$ENV_FILE" ]; then
  echo "$ENV_FILE がありません。env/$ENV_NAME.example.json をコピーして Supabase の URL・キーを設定してください。" >&2
  exit 1
fi
if [ "$ENV_NAME" = prod ]; then
  echo "!!  本番の Supabase に接続します。記録の追加・削除は実際のデータに反映されます。"
fi

flutter run -d web-server \
  --web-port=8080 \
  --web-hostname=0.0.0.0 \
  --dart-define-from-file="$ENV_FILE"
