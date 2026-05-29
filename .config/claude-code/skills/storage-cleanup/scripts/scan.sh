#!/usr/bin/env bash
# storage-cleanup skill / scan phase (WSL2 / Linux)
# Claude 旧バージョン溜まりを中心に調査する（削除しない）。
set -euo pipefail

VERSIONS_DIR="${HOME}/.local/share/claude/versions"
TMP_OLDER_DAYS="${1:-7}"   # /tmp の「N日より前」既定 7

echo "================ Storage Cleanup : SCAN (WSL/Linux) ================"

# 現行バージョン
current=""
if command -v claude >/dev/null 2>&1; then
  current="$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
fi
echo "現行 Claude バージョン : ${current:-(検出不可)}"

echo
echo "[1] Claude 旧バージョン  (${VERSIONS_DIR})"
reclaim=0
if [[ -d "$VERSIONS_DIR" ]]; then
  while IFS= read -r d; do
    name="$(basename "$d")"
    kb="$(du -sk "$d" 2>/dev/null | cut -f1)"
    mb=$(( kb / 1024 ))
    if [[ "$name" == "$current" ]]; then
      printf '  %-12s %6s MB  <= 現行(保持)\n' "$name" "$mb"
    else
      printf '  %-12s %6s MB  削除候補\n' "$name" "$mb"
      reclaim=$(( reclaim + mb ))
    fi
  done < <(find "$VERSIONS_DIR" -mindepth 1 -maxdepth 1 | sort)
  echo "  --- 旧バージョン回収見込み: ${reclaim} MB ---"
else
  echo "  (versions ディレクトリなし)"
fi

echo
echo "[2] /tmp 内の古いゴミ（${TMP_OLDER_DAYS}日より前・TOP15）"
find /tmp -mindepth 1 -maxdepth 1 -mtime "+${TMP_OLDER_DAYS}" -printf '%s\t%p\n' 2>/dev/null \
  | sort -nr | head -15 \
  | awk '{ printf "  %8.1f MB  %s\n", $1/1024/1024, $2 }' || true

echo
echo "[3] ~/.cache 大物 TOP10（参考）"
if [[ -d "${HOME}/.cache" ]]; then
  du -sm "${HOME}/.cache"/* 2>/dev/null | sort -nr | head -10 | awk '{ printf "  %6s MB  %s\n", $1, $2 }' || true
fi

echo
df -h "$HOME" | awk 'NR==1 || NR==2 { print "  " $0 }'
echo "==================================================================="
echo "削除は clean.sh --versions / --old-tmp で実行（--dry-run で事前確認）"
