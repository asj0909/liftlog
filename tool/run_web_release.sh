#!/usr/bin/env bash
# Web を release ビルド（最適化したビルド。接続先とは別）して静的サーバーで配信する（Codespaces で debug が読み込み中のまま止まるときに使う）
# 使い方：リポジトリのルートで ./tool/run_web_release.sh [dev|prod]（スクリプト内でルートへ移動するので、別の場所からはパスを指定して実行できる）
# debug（run_web_debug.sh）と同じ 8080 番を使うので、先に debug のターミナルで q を押して終了しておく
# コードを変えたら Ctrl + C で止めて、もう一度実行する（毎回ビルドし直す）
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

flutter build web --dart-define-from-file="$ENV_FILE"

# 静的サーバー dhttpd は初回だけ入れる
if ! dart pub global list | grep -q '^dhttpd '; then
  dart pub global activate dhttpd
fi

echo "==> http://0.0.0.0:8080 で配信します（ポートタブで 8080 を開く。停止は Ctrl + C）"
dart pub global run dhttpd --path build/web --host 0.0.0.0 --port 8080
