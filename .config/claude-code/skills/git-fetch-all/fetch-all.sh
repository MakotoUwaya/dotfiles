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
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

while IFS= read -r repo; do
  [[ -z "$repo" ]] && continue
  total=$((total + 1))
  idx=$total

  (
    output=$(git -C "$repo" fetch --prune origin 2>&1) || true
    if echo "$output" | grep -q "^fatal:\|^error:"; then
      echo "$repo" > "$tmpdir/${idx}.repo"
      echo "ERROR" > "$tmpdir/${idx}.status"
      echo "$output" > "$tmpdir/${idx}.output"
    elif [[ -n "$output" ]]; then
      echo "$repo" > "$tmpdir/${idx}.repo"
      echo "UPDATED" > "$tmpdir/${idx}.status"
      echo "$output" > "$tmpdir/${idx}.output"
    fi
  ) &

  if (( total % PARALLEL == 0 )); then
    wait
  fi
done <<< "$repos"

wait

# --- サマリ出力 ---
echo "Total: $total repos fetched"
echo ""

shopt -s nullglob
for repo_file in "$tmpdir"/*.repo; do
  idx=$(basename "$repo_file" .repo)
  repo_path=$(cat "$repo_file")
  status=$(cat "$tmpdir/${idx}.status")
  output_file="$tmpdir/${idx}.output"

  if [[ "$status" == "ERROR" ]]; then
    echo "ERROR:${repo_path}"
    cat "$output_file"
    echo ""
    continue
  fi

  echo "REPO:${repo_path}"
  while IFS= read -r line; do
    if echo "$line" | grep -q '^\s*\* \[new branch\]'; then
      branch=$(echo "$line" | sed 's/.*-> origin\///')
      echo "  NEW:${branch}"
    elif echo "$line" | grep -q '^\s*\* \[new tag\]'; then
      tag=$(echo "$line" | sed 's/.*\* \[new tag\]\s*//' | sed 's/\s*->.*//')
      echo "  TAG:${tag}"
    elif echo "$line" | grep -q '^\s*- \[deleted\]'; then
      branch=$(echo "$line" | sed 's/.*-> origin\///')
      echo "  DEL:${branch}"
    elif echo "$line" | grep -q '(forced update)'; then
      branch=$(echo "$line" | sed 's/.*-> origin\///' | sed 's/\s*(forced update)//')
      echo "  FORCE:${branch}"
    elif echo "$line" | grep -q '^\s\+[0-9a-f]'; then
      branch=$(echo "$line" | sed 's/.*-> origin\///')
      echo "  UPD:${branch}"
    fi
  done < "$output_file"
  echo ""
done
