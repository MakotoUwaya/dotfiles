## GateGuard 対応ルール

`everything-claude-code` プラグインの GateGuard フックは `[Fact-Forcing Gate]` エラーで Edit / Write / Destructive Bash をブロックすることがある。**ゲートを止めず、要求された事実を先に提示して通すこと。**

### 現在の有効範囲（2026-05-23 方針転換）

`~/.claude/settings.json` の `env.ECC_DISABLED_HOOKS` で **Routine Bash の Gate のみ無効化済み** (`pre:bash:gateguard-fact-force`)。鬱陶しさのトレードオフ。
残る以下の Gate は **維持する**（事故予防価値が高い）:

- **Edit / Write / MultiEdit** — ファイルごと初回 1 回。変更影響範囲を context に書き込ませる
- **Destructive Bash** — `rm -rf` / `git reset --hard` / `git push --force` / `drop table` 等、毎コマンド初回

それ以外の全面無効化（`ECC_GATEGUARD=off`、Edit/Write Gate の無効化）は **してはいけない**。+2.25 ポイントの品質優位を失う。

### 動作原理

GateGuard は 3 段階構造（deny → force → allow on retry）。Edit/Write/Destructive Bash の初回ツール呼び出しは事実を事前提示していても **必ず 1 回 deny される**。同じ操作をリトライすれば通過する。エラーメッセージ末尾の "Present the facts, then retry the same operation" がこれを示している。

実装上 `~/.claude/settings*.json` への Edit/Write は除外されているが、**symlink の実体パスが `.config/claude-code/settings.json` 等の場合は除外パターンにマッチせず deny される**。御屋形様の dotfiles 構成では実体パスを直接 Edit する都合上、事実提示が必要になる。

### 発火タイミング

| Gate | 発火 |
|------|------|
| ~~Routine Bash~~ | ~~セッション初回 1 回のみ~~ → **無効化済み** |
| Edit / MultiEdit | ファイルごとに初回 1 回 |
| Write | 新規ファイル作成の初回 1 回 |
| Destructive Bash | `rm -rf` / `git reset --hard` / `git push --force` / `drop table` 等は毎回 |

「Edit/Write が頻発しているように見える」場合、事実を提示せずに同じ操作をリトライしている可能性が高い。

### 各 Gate の提示テンプレ

**Write（新規ファイル作成）**

1. このファイルを呼ぶ側の file:line（自動読み込み系なら読み込み元の仕組みを明示）
2. Glob / ls で既存に同目的のファイルがないことを確認した結果
3. データファイルを読み書きするなら、フィールド名・構造・日付フォーマット（synthetic 値で）
4. ユーザー指示の verbatim 引用

**Edit / MultiEdit（既存ファイル編集の初回）**

1. このファイルを import / require している全ファイル（rg で確認）
2. 変更で影響する public 関数 / クラス
3. データファイルを読み書きするなら、フィールド名・構造・日付フォーマット
4. ユーザー指示の verbatim 引用

**Destructive Bash（毎回）**

1. このコマンドが変更 / 削除する全ファイル・データ
2. ロールバック手順を 1 行で
3. ユーザー指示の verbatim 引用

### 運用上の注意

- 事実提示は「ブロックを回避するための儀式」ではなく、investigation そのものが品質を上げる仕組み。形式だけ整えて中身を空にしない
- ファイル単位 / セッション単位の発火なので、毎ターン提示する必要はない
- 提示後に同じツール呼び出しをリトライすればゲートは通過する
