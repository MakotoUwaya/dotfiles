## dotfiles に新しい設定ファイルを追加する手順

`.gitignore` はホワイトリスト方式（`/*` `/.config/**` で全除外 → `!` で個別許可）。
新しい `.config/xxx` を追加する際は以下 3 点をセットで行うこと：

1. `.gitignore` に除外例外を追加
   - 追加前に `.gitignore` を Read して既存エントリを確認し、重複する行を書かないこと
   - `!/.config/xxx/` と `!/.config/xxx/対象ファイル` を追加
   - `.claude/` 配下も同様（`/.claude/**` で除外されている）
2. `.bin/install.sh` に `make_symlink` 行を追加（`~/.config/xxx` → `$DOTDIR/.config/xxx`）
3. `git check-ignore -v <対象ファイル>` で追跡対象になったことを確認してからレビューに出す
