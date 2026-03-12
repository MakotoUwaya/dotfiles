## MCP サーバー導入ポリシー

- 公式（Anthropic 提供の Connector）以外の MCP サーバーは原則導入禁止
- OSS の MCP サーバー（npm パッケージ等）を新たに追加提案しないこと
- 既に導入済みの MCP サーバー（DocBase, Redmine, TeamSpirit 等）はそのまま利用可

## MCP ツールのスキーマ事前ロード

- スキルやワークフローで複数の MCP ツールを使用する場合、**最初のステップとして使用する全ツールのスキーマを `ToolSearch` で並列取得**すること
- ツール呼び出し直前にスキーマを個別取得すると、ラウンドトリップが増えて体感速度が悪化する
- 例: `ToolSearch("select:mcp__teamspiritMcp__clockIn,mcp__claude_ai_Slack__slack_send_message")`
