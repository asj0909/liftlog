#!/usr/bin/env bash
# Play ストア提出用の AAB（Android App Bundle）を作る。
# 使い方：リポジトリのルートで ./tool/build_release_aab.sh
#
# - 接続先は本番の Supabase（env/prod.json）
# - 署名はアップロード鍵（android/key.properties）。なければ止める
# - バージョンは pubspec.yaml の version。ストアに上げるたびに + の後ろ（versionCode）を 1 増やす
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f env/prod.json ]; then
  echo "env/prod.json がありません。env/prod.example.json をコピーして本番の Supabase の URL・キーを設定してください。" >&2
  exit 1
fi
if [ ! -f android/key.properties ]; then
  echo "android/key.properties がありません。先に ./tool/create_upload_key.sh を実行してください。" >&2
  exit 1
fi

echo "==> バージョン：$(grep -m1 '^version:' pubspec.yaml)"
echo "    （前回ストアに上げたものより + の後ろが大きいことを確認してください）"

# Gradle がメモリ不足で強制終了しないよう、残っているデーモンを止めておく
(cd android && ./gradlew --stop >/dev/null 2>&1) || true

flutter build appbundle --release --dart-define-from-file=env/prod.json

echo
echo "==> 作成しました：build/app/outputs/bundle/release/app-release.aab"
echo "    Codespace のエクスプローラーで右クリック →「ダウンロード」し、Play Console にアップロードします。"
