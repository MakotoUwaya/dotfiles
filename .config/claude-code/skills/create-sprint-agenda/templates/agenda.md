# 参加者
@yoshinori.okino @taichi.imai @naoya.oda @atsushi.fujita @atsuki.omura @makoto.uwaya

# 前スプリント ゴール達成状況振り返り

{{RETROSPECTIVE}}

# Zoho Sprints 更新

スプリントの終了と開始を行う。

- [Square 品質維持 2026 2Q](https://sprints.zoho.com/workspace/eseikatsu#P44/board/SP2)
- [アカウントサービス 品質維持 2026 2Q](https://sprints.zoho.com/workspace/eseikatsu#P44/board/SP2)
- [いい生活アカウント MFA 全法人展開・Passkeys 導入](https://sprints.zoho.com/workspace/eseikatsu#P59/board/SP1)

# 対応予定ピックアップ

## ロードマップアイテム

[Epic ボード](https://gitlab.com/groups/eseikatsu/es-account/-/epic_boards/3890#/)

完了したものをクローズし、対応時期を調整する。

## バックログ

[優先度一覧](https://claude.ai/code/artifact/3a9827d3-1858-4e65-8f22-b825dbeb7486) / [カンバンボード](https://gitlab.com/groups/eseikatsu/es-account/-/boards/4911856)

{{BACKLOG}}

- 作業日指定や締切があるタスクを事前に確認
    - `effort::期日あり` ラベル + Due date で抽出する

## インフラコスト確認

コストインパクトのある課題があれば優先して対処する。

- AWS
    - [Square](https://us-east-1.console.aws.amazon.com/costmanagement/home?region=ap-southeast-2#/cost-explorer?chartStyle=STACK&costAggregate=unBlendedCost&endDate={{COST_END}}&excludeForecasting=false&filter=%5B%7B%22dimension%22:%7B%22id%22:%22LinkedAccount%22,%22displayValue%22:%22%E9%80%A3%E7%B5%90%E3%82%A2%E3%82%AB%E3%82%A6%E3%83%B3%E3%83%88%22%7D,%22operator%22:%22INCLUDES%22,%22values%22:%5B%7B%22value%22:%22117786002394%22,%22displayValue%22:%22Square%20Develop%20(117786002394)%22%7D,%7B%22value%22:%22251488297832%22,%22displayValue%22:%22Square%20Production%20(251488297832)%22%7D%5D%7D%5D&futureRelativeRange=CUSTOM&granularity=Monthly&groupBy=%5B%22Service%22%5D&historicalRelativeRange=CUSTOM&isDefault=true&reportMode=STANDARD&reportName=%E6%96%B0%E3%81%97%E3%81%84%E3%82%B3%E3%82%B9%E3%83%88%E3%81%A8%E4%BD%BF%E7%94%A8%E7%8A%B6%E6%B3%81%E3%83%AC%E3%83%9D%E3%83%BC%E3%83%88&showOnlyUncategorized=false&showOnlyUntagged=false&startDate=2026-04-01&usageAggregate=undefined&useNormalizedUnits=false) 物件検索 / メッセージ / メンテナンス
    - [b2b](https://us-east-1.console.aws.amazon.com/costmanagement/home?region=ap-southeast-2#/cost-explorer?chartStyle=STACK&costAggregate=unBlendedCost&endDate={{COST_END}}&excludeForecasting=false&filter=%5B%7B%22dimension%22:%7B%22id%22:%22LinkedAccount%22,%22displayValue%22:%22%E9%80%A3%E7%B5%90%E3%82%A2%E3%82%AB%E3%82%A6%E3%83%B3%E3%83%88%22%7D,%22operator%22:%22INCLUDES%22,%22values%22:%5B%7B%22value%22:%22191989898127%22,%22displayValue%22:%22B2B%20Production%20(191989898127)%22%7D,%7B%22value%22:%22533857624944%22,%22displayValue%22:%22B2B%20Staging%20(533857624944)%22%7D%5D%7D%5D&futureRelativeRange=CUSTOM&granularity=Monthly&groupBy=%5B%22Service%22%5D&historicalRelativeRange=CUSTOM&isDefault=true&reportMode=STANDARD&reportName=%E6%96%B0%E3%81%97%E3%81%84%E3%82%B3%E3%82%B9%E3%83%88%E3%81%A8%E4%BD%BF%E7%94%A8%E7%8A%B6%E6%B3%81%E3%83%AC%E3%83%9D%E3%83%BC%E3%83%88&showOnlyUncategorized=false&showOnlyUntagged=false&startDate=2026-04-01&usageAggregate=undefined&useNormalizedUnits=false) Square 業者間
    - [License Server](https://us-east-1.console.aws.amazon.com/costmanagement/home?region=ap-southeast-2#/cost-explorer?chartStyle=STACK&costAggregate=unBlendedCost&endDate={{COST_END}}&excludeForecasting=false&filter=%5B%7B%22dimension%22:%7B%22id%22:%22LinkedAccount%22,%22displayValue%22:%22%E9%80%A3%E7%B5%90%E3%82%A2%E3%82%AB%E3%82%A6%E3%83%B3%E3%83%88%22%7D,%22operator%22:%22INCLUDES%22,%22values%22:%5B%7B%22value%22:%22949079036407%22,%22displayValue%22:%22License%20Servers%20Production%20(949079036407)%22%7D,%7B%22value%22:%22790674929631%22,%22displayValue%22:%22License%20Servers%20Staging%20(790674929631)%22%7D%5D%7D%5D&futureRelativeRange=CUSTOM&granularity=Monthly&groupBy=%5B%22Service%22%5D&historicalRelativeRange=CUSTOM&isDefault=true&reportMode=STANDARD&reportName=License&showOnlyUncategorized=false&showOnlyUntagged=false&startDate=2026-04-01&usageAggregate=undefined&useNormalizedUnits=false) ライセンスサーバ
- Google Cloud
    - [ESA](https://console.cloud.google.com/billing/016D9A-F4049C-205D38/reports;timeRange=CUSTOM_RANGE;from=2026-04-01;to={{COST_END}};ancestors=folders%2F926993030571?project=es-account-dev) いい生活アカウント
- SendGrid / Twilio / Valimail
    - [Summary](https://docs.google.com/spreadsheets/d/1U6r0NXNID_TXYbjaZ1nADsCafkLSYwwf/edit?gid=896090851#gid=896090851) 月次推移
    - [Account Secret](https://docs.google.com/document/d/1E-d3iYpFmwVY8rCzF1IpXqZud5srEwdQQeflk3jiZKc/edit?tab=t.0) ログイン情報
    - [SendGrid Login](https://sendgrid.kke.co.jp/app?p=login.index) 送信メール数推移(ESA)
    - [Valimail SignIn](https://app.valimail.com/auth/users/sign_in) メールバリデーション運用ツール(無償)
    - [Twilio Login](https://www.twilio.com/login) Voice(業者間)

# プランニング

次期 Milestone に対象 Issue を紐付け、Weight を設定する。

## Square 物件検索 / メッセージ

- 織田さん [ボード](https://gitlab.com/groups/eseikatsu/es-square/-/boards/9839930?label_name[]=Square%E7%89%A9%E4%BB%B6%E6%A4%9C%E7%B4%A2&milestone_title={{MS_SQUARE}}#/)

## アカウントサービス

- 今井さん [ボード](https://gitlab.com/groups/eseikatsu/es-account/-/boards/4911856?assignee_username=taichi.imai&milestone_title={{MS_ESA}}#/)
- 藤田さん [ボード](https://gitlab.com/groups/eseikatsu/es-account/-/boards/4911856?assignee_username=atsushi.fujita&milestone_title={{MS_ESA}}#/)
- 小村さん [ボード](https://gitlab.com/groups/eseikatsu/es-account/-/boards/4911856?assignee_username=atsuki.omura&milestone_title={{MS_ESA}}#/)
- 上屋さん [ボード](https://gitlab.com/groups/eseikatsu/es-account/-/boards/4911856?assignee_username=makoto.uwaya&milestone_title={{MS_ESA}}#/)

## ライセンスサーバ

- 今井さん [ボード](https://gitlab.com/groups/eseikatsu/es-account/-/boards/4911856?assignee_username=taichi.imai&milestone_title={{MS_LS}}#/)

# 担当割り当て

MTG 後に `/record-sprint-plan` が記入する。
この節が次回の振り返りの基準になるため、見出しと表の形式は変更しない。
