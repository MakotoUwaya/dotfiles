## Git コマンド実行ルール

- 現在の作業ディレクトリ（CWD）と同じパスに対して `git -C <path>` を使わないこと
  - CWD 内のリポジトリ操作では `-C` オプションは不要
  - 例: CWD が `/home/m-uwaya/project` のとき `git -C /home/m-uwaya/project status` は冗長 → `git status` で十分
- `git add` と `git commit` は別々のコマンドとして実行すること
  - `&&` で繋げず、それぞれ独立した Bash ツール呼び出しで実行する
  - add の結果を確認してから commit する方が安全

## Git 操作の直列化（index.lock 防止）

- **git コマンドは必ず直列で実行すること**（並列実行禁止）
  - 複数の git コマンドを同一メッセージ内で並列に Bash 呼び出ししない
  - 例: `git status` と `git diff` を並列実行 → NG。順番に実行する
- **サブエージェントに git 操作を委任しない**
  - 実装・調査をサブエージェントに任せる場合でも、`git add` / `git commit` / `git push` はメインエージェントが行う
- `.git/index.lock` エラーが発生した場合:
  - まず `pgrep -x git` で実行中の git プロセスを確認する
  - プロセスがなければ `rm -f .git/index.lock` で削除してよい
  - プロセスがあれば完了を待つ
