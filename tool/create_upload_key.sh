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

# 以降に作るディレクトリ・鍵・key.properties を本人だけが読めるようにする
umask 077

KEY_DIR="${KEY_DIR:-$HOME/keys}"
# storeFile は android/app 基準で解決されるため、相対パスはここで絶対パスにしておく
case "$KEY_DIR" in
  /*) ;;
  *) KEY_DIR="$PWD/$KEY_DIR" ;;
esac
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
if [ "$PASSWORD" != "$(printf '%s' "$PASSWORD" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" ]; then
  # properties 形式では値の前の空白が読み飛ばされるため
  echo "パスワードの前後に空白は使えません。" >&2
  exit 1
fi

mkdir -p "$KEY_DIR"
# パスワードはコマンドライン引数に書かず（ps で見えるため）、環境変数経由で keytool に渡す
LIFTLOG_KEY_PASSWORD="$PASSWORD" keytool -genkeypair -v \
  -keystore "$KEY_FILE" -storetype JKS \
  -alias "$ALIAS" -keyalg RSA -keysize 2048 -validity 10000 \
  -storepass:env LIFTLOG_KEY_PASSWORD -keypass:env LIFTLOG_KEY_PASSWORD \
  -dname "CN=LiftLog"

# properties 形式のエスケープ：バックスラッシュを二重にする（build.gradle.kts は UTF-8 で読む）
escape_property() {
  printf '%s' "$1" | sed 's/\\/\\\\/g'
}
ESCAPED_PASSWORD="$(escape_property "$PASSWORD")"
ESCAPED_KEY_FILE="$(escape_property "$KEY_FILE")"

# 既存の key.properties は umask が効かないので、書き込む前に権限を絞る
if [ -f android/key.properties ]; then
  chmod 600 android/key.properties
fi
cat > android/key.properties <<PROPS
storePassword=$ESCAPED_PASSWORD
keyPassword=$ESCAPED_PASSWORD
keyAlias=$ALIAS
storeFile=$ESCAPED_KEY_FILE
PROPS

echo
echo "==> 鍵を作成しました：$KEY_FILE"
echo "==> android/key.properties を作成しました（Git には含まれません）"
echo "!!  $KEY_FILE とパスワードを、必ず Codespace の外にバックアップしてください。"
