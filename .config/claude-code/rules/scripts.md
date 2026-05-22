## スクリプト実行ルール

### スクリプト実行前の必須チェック

- データ処理・計算・ファイル生成などでスクリプトを実行する前に、**必ず `scripting-guide` スキルを参照**すること

### 繰り返し実行するスクリプト

- スキルのヘルパーなど、繰り返し使うスクリプトは **静的ファイル** として `~/.config/claude-code/skills/<skill-name>/` に配置する
- 動的にインライン生成せず、ファイルを引数付きで呼び出す
- 作成したスクリプトは `~/.claude/settings.json` の `permissions.allow` に登録して自動許可する

```json
{
  "permissions": {
    "allow": [
      "Bash(<interpreter> ~/.config/claude-code/skills/<skill-name>/<script>:*)"
    ]
  }
}
```

### 一時的なスクリプト

- 一度きりの処理や調査目的のスクリプトはインライン実行でよい
- ユーザーに都度実行許可を求める（動的許可）

## パッケージマネージャ利用ルール

### `npx` は使用禁止

`npx` / `pnpm dlx` / `bunx` のような **リモートから任意の npm パッケージをダウンロード即実行するコマンドは絶対に使わない**。

- サプライチェーン攻撃や悪意あるパッケージ実行のリスクが高い
- バージョンが固定されず再現性が無い
- 毎回ネットワーク経由でダウンロードするため遅い

### 代替: `mise` で global install する

外部 CLI ツール（`mmdc`, `markdownlint-cli2`, `prettier` 等）を使う必要がある場合、以下の手順で `mise` 経由で global install する:

```sh
# 例: mermaid-cli を global install
mise use -g npm:@mermaid-js/mermaid-cli

# install 後は PATH に通るのでそのまま実行
mmdc -i input.mmd -o output.svg
```

- `mise use -g npm:<package>` で `~/.config/mise/config.toml` に追記されバージョン管理される
- `which <cmd>` で実体パスを確認できる状態にしてから使う
- ローカルプロジェクト依存（`package.json` の `devDependencies`）で済む場合はそちらを優先する
- 未インストールの場合はユーザーに `mise use -g npm:<package>` の実行を依頼する
