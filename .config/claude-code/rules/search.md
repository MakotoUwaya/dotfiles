## 検索コマンド実行ルール

Bash ツールでファイル検索やテキスト検索を行う場合は、`rg`（ripgrep）を使うこと。

### テキスト検索（grep の代替）

- `grep` や `ag` ではなく `rg` を使う
- 例: `rg "pattern" --type py`
- 例: `rg -l "TODO" src/` （ファイル名のみ）

### ファイル検索（find / fd の代替）

- `find` や `fd` ではなく `rg --files` を使う
- 例: `rg --files -g "*.ts" src/` （glob パターンでファイル一覧）
- 例: `rg --files | rg "config"` （ファイル名で絞り込み）

### 注意

- Claude Code の組み込みツール（Glob, Grep, Read）が使える場面ではそちらを優先する
- 組み込みツールでは対応できない複雑な検索や、明示的に Bash を使う場面でのみ `rg` を使用する
