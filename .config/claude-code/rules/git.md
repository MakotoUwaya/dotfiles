## Git コマンド実行ルール

- 現在の作業ディレクトリ（CWD）と同じパスに対して `git -C <path>` を使わないこと
  - CWD 内のリポジトリ操作では `-C` オプションは不要
  - 例: CWD が `/home/m-uwaya/project` のとき `git -C /home/m-uwaya/project status` は冗長 → `git status` で十分
- `git add` と `git commit` は別々のコマンドとして実行すること
  - `&&` で繋げず、それぞれ独立した Bash ツール呼び出しで実行する
  - add の結果を確認してから commit する方が安全
