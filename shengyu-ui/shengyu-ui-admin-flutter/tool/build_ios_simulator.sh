#!/usr/bin/env bash
set -euo pipefail

export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"
export PATH="/Users/zsy/.gem/ruby/4.0.0/bin:${PATH}"

FLUTTER_BIN="${FLUTTER_BIN:-/Users/zsy/app/flutter/bin/flutter}"

if ! command -v pod >/dev/null 2>&1; then
  echo "未找到 CocoaPods。请先安装 CocoaPods，或把 pod 所在目录加入 PATH。" >&2
  exit 1
fi

"${FLUTTER_BIN}" build ios --simulator --debug --no-pub
