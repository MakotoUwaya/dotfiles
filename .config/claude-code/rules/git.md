## Git コマンド実行ルール

- 現在の作業ディレクトリ（CWD）と同じパスに対して `git -C <path>` を使わないこと
  - CWD 内のリポジトリ操作では `-C` オプションは不要
  - 例: CWD が `/home/m-uwaya/project` のとき `git -C /home/m-uwaya/project status` は冗長 → `git status` で十分
