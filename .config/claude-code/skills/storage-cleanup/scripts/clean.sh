#!/usr/bin/env bash
# storage-cleanup skill / clean phase (WSL2 / Linux)
# 現行バージョンを保持し、それ以外の Claude 旧バージョン等を削除する。
set -euo pipefail

VERSIONS_DIR="${HOME}/.local/share/claude/versions"
DO_VERSIONS=0
DO_OLD_TMP=0
TMP_OLDER_DAYS=7
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: clean.sh [--versions] [--old-tmp [DAYS]] [--all] [--dry-run]
  --versions        Claude 旧バージョン（現行以外）を削除
  --old-tmp [DAYS]  /tmp の N日より前のファイルを削除（既定 7）
  --all             上記すべて
  --dry-run         削除せず対象のみ表示
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --versions) DO_VERSIONS=1 ;;
    --old-tmp)  DO_OLD_TMP=1; if [[ "${2:-}" =~ ^[0-9]+$ ]]; then TMP_OLDER_DAYS="$2"; shift; fi ;;
    --all)      DO_VERSIONS=1; DO_OLD_TMP=1 ;;
    --dry-run)  DRY_RUN=1 ;;
    -h|--help)  usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

if [[ $DO_VERSIONS -eq 0 && $DO_OLD_TMP -eq 0 ]]; then usage; exit 1; fi

free_before="$(df -m "$HOME" | awk 'NR==2 {print $4}')"

if [[ $DO_VERSIONS -eq 1 ]]; then
  current=""
  if command -v claude >/dev/null 2>&1; then
    current="$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || true)"
  fi
  echo "[versions] 現行 ${current:-?} を保持、それ以外を削除"
  if [[ -d "$VERSIONS_DIR" ]]; then
    while IFS= read -r d; do
      name="$(basename "$d")"
      [[ "$name" == "$current" ]] && continue
      if [[ $DRY_RUN -eq 1 ]]; then
        echo "  [dry-run] rm -rf $d"
      else
        rm -rf "$d" && echo "  削除: $d"
      fi
    done < <(find "$VERSIONS_DIR" -mindepth 1 -maxdepth 1 | sort)
  fi
fi

if [[ $DO_OLD_TMP -eq 1 ]]; then
  echo "[old-tmp] /tmp の ${TMP_OLDER_DAYS}日より前を削除"
  if [[ $DRY_RUN -eq 1 ]]; then
    find /tmp -mindepth 1 -maxdepth 1 -mtime "+${TMP_OLDER_DAYS}" 2>/dev/null \
      | sed 's/^/  [dry-run] rm -rf /' || true
  else
    # 自分が所有するもののみ、安全に削除
    find /tmp -mindepth 1 -maxdepth 1 -user "$(id -un)" -mtime "+${TMP_OLDER_DAYS}" \
      -exec rm -rf {} + 2>/dev/null || true
    echo "  完了"
  fi
fi

if [[ $DRY_RUN -eq 0 ]]; then
  free_after="$(df -m "$HOME" | awk 'NR==2 {print $4}')"
  echo
  echo "空き変化: $(( free_before / 1024 )) GB -> $(( free_after / 1024 )) GB (+$(( (free_after - free_before) )) MB)"
fi
