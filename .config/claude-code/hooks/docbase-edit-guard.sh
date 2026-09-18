#!/bin/bash
# PreToolUse hook: DocBase連携ファイル編集時に Pull → Edit → Push フローをリマインドする
#
# stdin: {"tool_name": "Edit|Write", "tool_input": {"file_path": "..."}}
# exit 0: 常に許可（リマインドのみ）

# Edit/Write の呼び出しごとに走るため、対象外のケースは外部プロセスを
# 起こす前にシェル組み込みだけで振り落とす（git-lock-guard.sh と同じ方針）。

set -euo pipefail

INPUT=$(cat)

# 対象は works/works 配下のみ。JSON にも CWD にも現れないなら無関係。
# file_path が相対パスのケースは CWD 側で拾う。
case "$INPUT$PWD" in
  *works/works*) ;;
  *) exit 0 ;;
esac

TOOL_NAME=""
FILE_PATH=""
eval "$(printf '%s' "$INPUT" | jq -r '@sh "TOOL_NAME=\(.tool_name // "") FILE_PATH=\(.tool_input.file_path // "")"' 2>/dev/null || true)"

# Edit/Write 以外は無視
case "$TOOL_NAME" in
  Edit|Write) ;;
  *) exit 0 ;;
esac

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
