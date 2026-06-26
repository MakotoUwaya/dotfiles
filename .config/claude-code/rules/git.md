## Git コマンド実行ルール

- CWD 内のリポジトリに `git -C <CWDと同じパス>` を使わない
- `git add` と `git commit` は別々の Bash 呼び出しで実行する
- **git コマンドは必ず直列実行**（並列 Bash 呼び出し禁止。index.lock 防止）
- **サブエージェントに git 書き込み操作を委任しない**（add/commit/push はメインが行う）
- `index.lock` エラー時: `pgrep -x git` で確認 → プロセスなければ `rm -f .git/index.lock`
