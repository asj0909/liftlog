#!/usr/bin/env bash
# Play ストア提出用の「アップロード鍵」を作り、android/key.properties を用意する。
# 使い方：リポジトリのルートで ./tool/create_upload_key.sh
#
# 注意
# - 鍵はリポジトリの外（既定は ~/keys）に作る。Git に入れない
# - Codespace を削除すると ~/keys も消える。作ったら必ず手元の PC やパスワード管理ツールにバックアップする
#   （Play アプリ署名を使うので、なくしても Play Console から再登録はできるが手間がかかる）
set -euo pipefail
cd "$(dirname "$0")/.."

KEY_DIR="${KEY_DIR:-$HOME/keys}"
KEY_FILE="$KEY_DIR/liftlog-upload.jks"
ALIAS="upload"

if [ -f "$KEY_FILE" ]; then
  echo "すでに鍵があります：$KEY_FILE（上書きしません）" >&2
  exit 1
fi
if ! command -v keytool >/dev/null; then
  echo "keytool がありません。先に bash tool/setup-android-sdk.sh で JDK を入れてください。" >&2
  exit 1
fi

read -r -s -p "鍵のパスワード（6 文字以上）: " PASSWORD; echo
read -r -s -p "もう一度: " PASSWORD2; echo
if [ "$PASSWORD" != "$PASSWORD2" ] || [ "${#PASSWORD}" -lt 6 ]; then
  echo "パスワードが一致しないか、短すぎます。" >&2
  exit 1
fi

mkdir -p "$KEY_DIR"
keytool -genkeypair -v \
  -keystore "$KEY_FILE" -storetype JKS \
  -alias "$ALIAS" -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass "$PASSWORD" -keypass "$PASSWORD" \
  -dname "CN=LiftLog"

umask 077
cat > android/key.properties <<PROPS
storePassword=$PASSWORD
keyPassword=$PASSWORD
keyAlias=$ALIAS
storeFile=$KEY_FILE
PROPS

echo
echo "==> 鍵を作成しました：$KEY_FILE"
echo "==> android/key.properties を作成しました（Git には含まれません）"
echo "!!  $KEY_FILE とパスワードを、必ず Codespace の外にバックアップしてください。"
