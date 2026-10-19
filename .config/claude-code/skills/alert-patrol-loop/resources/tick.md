# alert-patrol-loop: 1 回分の巡回手順

cron から毎時 :16 に読まれる。メインの履歴に積まれるので、返答は短く保つ。

## Step 0: 次回分を登録する（最初に必ず）

`date '+%H %d %m'` で現在の時・日・月を取り、次の「HH:16」（今が HH:16 以降なら次の時間。日・月の繰り上がりに注意）を一回きりジョブで登録する。

```
CronCreate(
  cron="16 <時> <日> <月> *",
  recurring=false,
  prompt="/home/m-uwaya/.claude/skills/alert-patrol-loop/resources/tick.md を Read して、その手順どおりに 1 回分の巡回を実行する（alert-patrol-loop）")
```

途中で失敗しても連鎖が切れないよう、巡回より先に登録する。`recurring: true` にしない。

## Step 1: 巡回（未対応を数える）

```
Agent(subagent_type="general-purpose", model="haiku", description="アラート巡回", prompt=<以下>)
```

```
~/.claude/plugins/cache/eseikatsu-product-docs 配下で `rg --files -g alert-patrol.md` を実行し、最も新しいバージョンのファイルを Read して、その手順どおりに未対応アラートを数え、定義された形式で返す。
定義の tools にある mcp__claude_ai_Slack__* は、このセッションでは名前が違う。ToolSearch で "slack_read_channel slack_read_thread" を検索し、見つかった実名のツールを使う。
読み取り専用。Slack への投稿・Splunk 検索はしない。
```

## Step 2: 0 件なら終了

返答が `未対応: 0 件` なら「未対応 0 件」と 1 行だけ返して終了する。

## Step 3: 1 件以上なら精査

```
Agent(subagent_type="general-purpose", description="アラート精査", prompt=<以下>)
```

model は指定しない（親のモデルを使う）。

```
~/.claude/plugins/cache/eseikatsu-product-docs 配下で `rg --files -g alert-investigator.md` を実行し、最も新しいバージョンのファイルを Read して、その手順どおりに以下の未対応アラートを精査し、定義された形式で返す。
参照される resources/ は、同じバージョンの skills/triage-external-access-alert/resources/ にある。
定義の tools にある mcp__claude_ai_Slack__* と mcp__zoho-mcp__ZohoCRM_searchRecords は、このセッションでは名前が違う。ToolSearch で "slack_read_channel slack_read_thread slack_search_public_and_private slack_send_message slack_create_canvas" と "searchRecords" を検索し、見つかった実名のツールを使う。Splunk は mcp__splunk__* のまま。
ブロックと @here 周知は絶対にしない。AskUserQuestion は使わない。

<Step 1 の返答の「- ts=...」行をそのまま>
```

## Step 4: 返答で分岐

| 返答 | 動作 |
| --- | --- |
| `SPLUNK_NG` | `/mcp` での再接続を依頼して終了 |
| `要人判断: なし` | 対象と判定ラベルを 1 行ずつ報告して終了 |
| `要人判断: あり` | 「人の判断が必要」ブロックをそのまま提示して停止 |

## 禁止事項

- メインで Slack / Splunk を直接叩かない。サブエージェントの返答を検算しない
- ブロックと `@here` 周知はしない。`AskUserQuestion` で聞かない
- サブエージェントの返答を要約し直したり貼り直したりしない
