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
