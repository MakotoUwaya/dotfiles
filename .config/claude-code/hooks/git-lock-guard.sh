#!/bin/bash
# PreToolUse hook: git コマンド実行前にプロセスなしの index.lock を自動削除する
#
# stdin: {"tool_name": "Bash", "tool_input": {"command": "..."}}
# exit 0: 許可, exit 2: ブロック
#
# このフックは Bash ツールの呼び出しごとに走る。外部プロセスの起動が
# 1 回あたり 250ms 前後かかる環境（Windows + EDR 常駐）では、jq や grep を
# 何回呼ぶかがそのまま体感速度になるため、以下の順で足切りする。
#   1. シェル組み込みのパターンマッチ（プロセス 0 個）
#   2. jq 1 回で必要な値をまとめて取る
#   3. git rev-parse 以降は本当に git コマンドだった場合のみ

set -euo pipefail

INPUT=$(cat)

# JSON 全体に git という文字列が無ければ git コマンドではありえない
case "$INPUT" in
  *git*) ;;
  *) exit 0 ;;
esac

TOOL_NAME=""
COMMAND=""
eval "$(printf '%s' "$INPUT" | jq -r '@sh "TOOL_NAME=\(.tool_name // "") COMMAND=\(.tool_input.command // "")"' 2>/dev/null || true)"

# Bash ツール以外は無視
if [ "$TOOL_NAME" != "Bash" ]; then
  exit 0
fi

# git コマンド以外は無視（grep -qE '^\s*git\b' と同じ判定をシェル内で行う）
if [[ ! "$COMMAND" =~ ^[[:space:]]*git([^[:alnum:]_]|$) ]]; then
  exit 0
fi

# .git ディレクトリの探索（git rev-parse で正確に取得）
GIT_DIR=$(git rev-parse --git-dir 2>/dev/null) || exit 0
LOCK_FILE="$GIT_DIR/index.lock"

if [ ! -f "$LOCK_FILE" ]; then
  exit 0
fi

# git プロセスの実行確認。環境によって使える手段が異なる
# - Linux/WSL: pgrep
# - Windows (Git Bash): pgrep が無いため tasklist を使う。// は MSYS のパス変換抑止
# 判定手段が無い場合は「実行中」とみなし、lock を消さない安全側に倒す
git_is_running() {
  if command -v pgrep > /dev/null 2>&1; then
    pgrep -x git > /dev/null 2>&1
  elif command -v tasklist > /dev/null 2>&1; then
    tasklist //FI "IMAGENAME eq git.exe" //NH 2>/dev/null | grep -qi '^git\.exe'
  else
    return 0
  fi
}

# ロックファイルが存在する場合、git プロセスを確認
if git_is_running; then
  echo "BLOCKED: .git/index.lock が存在し、git プロセスが実行中です。完了を待ってください。" >&2
  exit 2
fi

# プロセスなし = stale lock → 自動削除
rm -f "$LOCK_FILE"
echo "Removed stale $LOCK_FILE (git プロセスなし)" >&2
exit 0
