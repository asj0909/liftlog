#!/usr/bin/env bash
# Codespaces 作成時に一度だけ実行される：Flutter SDK の導入とプロジェクト初期化
set -euo pipefail

echo "==> Web 確認用の簡易サーバー（python3 -m http.server）に使う Python"
if ! command -v python3 >/dev/null; then
  sudo apt-get update -y && sudo apt-get install -y python3
fi

if [ ! -d "$HOME/flutter" ]; then
  echo "==> Flutter SDK（stable）を取得"
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$HOME/flutter"
fi
export PATH="$HOME/flutter/bin:$PATH"

flutter config --no-analytics >/dev/null
flutter config --enable-web >/dev/null
flutter --version

echo "==> プロジェクトの初期化（tool/setup.sh）"
bash tool/setup.sh
