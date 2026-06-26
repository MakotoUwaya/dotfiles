## スクリプト実行ルール

- データ処理・計算・ファイル生成の前に **`scripting-guide` スキルを参照**すること
- 繰り返し使うスクリプトは `~/.config/claude-code/skills/<skill-name>/` に静的配置し、`permissions.allow` に登録
- 一度きりの処理はインライン実行可（都度許可）

## パッケージマネージャ利用ルール

**`npx` / `pnpm dlx` / `bunx` は使用禁止**（サプライチェーン攻撃リスク・バージョン非固定）。

外部 CLI が必要なら `mise use -g npm:<package>` で global install する。`devDependencies` で済む場合はそちらを優先。未インストールならユーザーに `mise use -g` の実行を依頼する。
