#!/bin/bash
# PreToolUse hook: git コマンド実行前にプロセスなしの index.lock を自動削除する
#
# stdin: {"tool_name": "Bash", "tool_input": {"command": "..."}}
# exit 0: 許可, exit 2: ブロック

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Bash ツール以外は無視
if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# git コマンド以外は無視
if ! echo "$COMMAND" | grep -qE '^\s*git\b'; then
  exit 0
fi

# .git ディレクトリの探索（git rev-parse で正確に取得）
GIT_DIR=$(git rev-parse --git-dir 2>/dev/null) || exit 0
LOCK_FILE="$GIT_DIR/index.lock"

if [ ! -f "$LOCK_FILE" ]; then
  exit 0
fi

# ロックファイルが存在する場合、git プロセスを確認
if pgrep -x git > /dev/null 2>&1; then
  echo "BLOCKED: .git/index.lock が存在し、git プロセスが実行中です。完了を待ってください。" >&2
  exit 2
fi

# プロセスなし = stale lock → 自動削除
rm -f "$LOCK_FILE"
echo "Removed stale $LOCK_FILE (git プロセスなし)" >&2
exit 0
