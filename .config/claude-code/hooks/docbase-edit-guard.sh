#!/bin/bash
# PreToolUse hook: DocBase連携ファイル編集時に Pull → Edit → Push フローをリマインドする
#
# stdin: {"tool_name": "Edit|Write", "tool_input": {"file_path": "..."}}
# exit 0: 常に許可（リマインドのみ）

set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Edit/Write 以外は無視
case "$TOOL_NAME" in
  Edit|Write) ;;
  *) exit 0 ;;
esac

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[ -z "$FILE_PATH" ] && exit 0

# 相対パスを絶対パスに変換
if [[ "$FILE_PATH" != /* ]]; then
  FILE_PATH="$PWD/$FILE_PATH"
fi

# works/works/ 配下でなければ無視
case "$FILE_PATH" in
  */works/works/*) ;;
  *) exit 0 ;;
esac

# ファイルが存在しない場合はスキップ（Write で新規作成）
[ ! -f "$FILE_PATH" ] && exit 0

# Front Matter に post_id: があるかチェック
if head -30 "$FILE_PATH" 2>/dev/null | grep -q 'post_id:'; then
  echo "⚠ DocBase連携ファイルです。Pull → Edit → Push フローを確認してください (CLAUDE.md 参照)" >&2
fi

exit 0
