#!/usr/bin/env bash
# ghq 管理下の全リポジトリを並列 fetch する
# Usage: fetch-all.sh [filter] [parallel]
#   filter   - grep パターンでリポジトリを絞り込む (例: github.com)
#   parallel - 並列数 (デフォルト: 8)

set -euo pipefail

FILTER="${1:-}"
PARALLEL="${2:-8}"

repos=$(ghq list --full-path)
if [[ -n "$FILTER" ]]; then
  repos=$(echo "$repos" | grep "$FILTER")
fi

total=0
success=0
errors=()

while IFS= read -r repo; do
  [[ -z "$repo" ]] && continue
  total=$((total + 1))

  # バックグラウンドで fetch し、並列数を制御
  (
    if ! output=$(git -C "$repo" fetch --prune origin 2>&1); then
      echo "ERROR:${repo}:${output}" >&2
    elif [[ -n "$output" ]]; then
      echo "UPDATED:${repo}:${output}"
    fi
  ) &

  # 並列数に達したら待機
  if (( total % PARALLEL == 0 )); then
    wait
  fi
done <<< "$repos"

wait

echo "---"
echo "Total: $total repos fetched"
