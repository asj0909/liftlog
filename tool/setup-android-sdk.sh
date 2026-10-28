#!/usr/bin/env bash
# Codespaces（Linux）に APK ビルド用の Android SDK を導入する。
# エミュレーターは使えない（仮想化非対応）ため、ビルドに必要なものだけを入れる。
# 実行: bash tool/setup-android-sdk.sh
set -euo pipefail

ANDROID_HOME="${ANDROID_HOME:-$HOME/android-sdk}"
CMDLINE_TOOLS_ZIP="commandlinetools-linux-11076708_latest.zip"

echo "==> JDK 17"
if ! java -version 2>&1 | grep -q '"17'; then
  sudo apt-get update -y
  sudo apt-get install -y openjdk-17-jdk-headless unzip
fi
JAVA_HOME="$(dirname "$(dirname "$(readlink -f "$(command -v java)")")")"
export JAVA_HOME

echo "==> Android command-line tools"
if [ ! -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
  mkdir -p "$ANDROID_HOME/cmdline-tools"
  tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/tools.zip" "https://dl.google.com/android/repository/$CMDLINE_TOOLS_ZIP"
  unzip -q "$tmp/tools.zip" -d "$tmp"
  mv "$tmp/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
  rm -rf "$tmp"
fi
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

echo "==> SDK パッケージ（ライセンスに同意して導入）"
yes | sdkmanager --licenses >/dev/null || true
sdkmanager "platform-tools" "platforms;android-36" "build-tools;36.0.0"

echo "==> Flutter に SDK の場所を設定"
flutter config --android-sdk "$ANDROID_HOME" >/dev/null
flutter config --jdk-dir "$JAVA_HOME" >/dev/null
yes | flutter doctor --android-licenses >/dev/null || true

# 新しいターミナルでも使えるようにする
if ! grep -q "ANDROID_HOME" "$HOME/.bashrc"; then
  {
    echo "export ANDROID_HOME=\"$ANDROID_HOME\""
    echo "export JAVA_HOME=\"$JAVA_HOME\""
    echo 'export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"'
  } >> "$HOME/.bashrc"
fi

flutter doctor
echo
echo "完了。APK のビルド: flutter build apk --dart-define-from-file=env/dev.json"

# Codespaces（標準 8GB メモリ）では Flutter テンプレートの Gradle 設定（-Xmx8G）だと
# メモリ不足でデーモンが強制終了されるため、ヒープを抑える
if [ -f android/gradle.properties ]; then
  sed -i -E 's/-Xmx[0-9]+[GgMm]/-Xmx3g/; s/-XX:MaxMetaspaceSize=[0-9]+[GgMm]/-XX:MaxMetaspaceSize=1g/' android/gradle.properties
  grep -q '^kotlin.daemon.jvmargs' android/gradle.properties || echo 'kotlin.daemon.jvmargs=-Xmx1g' >> android/gradle.properties
fi
