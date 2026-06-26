## GateGuard 対応ルール

`[Fact-Forcing Gate]` エラーで Edit/Write/Destructive Bash がブロックされる。**要求された事実を提示してからリトライで通す。** 全面無効化禁止。

### 動作: deny → 事実提示 → リトライで通過

- **Edit/Write** — ファイルごと初回 1 回。symlink 実体パスが dotfiles 内の場合も発火する
- **Destructive Bash** — `rm -rf`/`git reset --hard`/`git push --force`/`drop table` 等、毎回

### 提示する事実

**Write:** 呼び出し元の file:line、同目的ファイルが無い確認結果、ユーザー指示の引用
**Edit:** import/require している全ファイル（rg 確認）、影響する public API、ユーザー指示の引用
**Destructive Bash:** 変更/削除対象、ロールバック手順 1 行、ユーザー指示の引用

事実提示は形式でなく investigation そのもの。空にしない。
