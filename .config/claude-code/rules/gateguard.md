## GateGuard 対応ルール

`everything-claude-code` プラグインの GateGuard フックが `[Fact-Forcing Gate]` エラーで Bash / Edit / Write をブロックすることがある。**ゲートを止めず、要求された事実を先に提示して通すこと。**

`ECC_GATEGUARD=off` や `ECC_DISABLED_HOOKS` で抑制してはいけない。ゲートは「重要な事実確認」を強制する仕組みであり、止めると本来検出されるべき設計ミス・破壊的操作のリスクが埋もれる。

### 動作原理

GateGuard は 3 段階構造（deny → force → allow on retry）。初回ツール呼び出しは事実を事前提示していても **必ず 1 回 deny される**。同じ操作をリトライすれば通過する。エラーメッセージ末尾の "Present the facts, then retry the same operation" がこれを示している。

### 発火タイミング（限定的、頻発しない）

| Gate | 発火 |
|------|------|
| Routine Bash | セッション初回 1 回のみ |
| Edit / MultiEdit | ファイルごとに初回 1 回 |
| Write | 新規ファイル作成の初回 1 回 |
| Destructive Bash | `rm -rf` / `git reset --hard` / `git push --force` / `drop table` 等は毎回 |

「頻発しているように見える」場合、事実を提示せずに同じ操作をリトライしている可能性が高い。

### 各 Gate の提示テンプレ

**Routine Bash（セッション初回）**

1. 現在のユーザー依頼を 1 文で
2. このコマンドが検証 / 生成するもの

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
