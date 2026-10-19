---
name: alert-patrol-loop
description: "#alert_他社からのアクセス検知 の定期巡回（毎時16分）をローカルセッションで開始する。一回きりジョブを毎回つなぎ直す連鎖方式で、繰り返しジョブの最大30分の遅れを避ける。プラグインのエージェント定義と Slack コネクタのツール名が合わない環境向けに、general-purpose で巡回・精査を代わりに行う。「アラート巡回を開始」「alert patrol」「他社アクセスの定期チェック」「毎時16分のチェック」で使用。1 件だけの精査は eseikatsu-product-docs:triage-external-access-alert の個別対応を使う。"
---

# Alert Patrol Loop

## Overview

`eseikatsu-product-docs:triage-external-access-alert` の定期実行を、この環境で確実に回すための起動スキル。
巡回・精査の中身はプラグインのエージェント定義（`alert-patrol.md` / `alert-investigator.md`）をそのまま使い、このスキルは次の 2 点だけを補う。

1. **一回きりジョブの連鎖**: 繰り返しジョブ（`recurring: true`）は周期の最大 50%（上限 30 分）遅れて発火する。WAF アラートは毎時 15 分に発報するので、:16 に確実に回すため、毎回の実行で次の :16 を一回きりジョブとして登録し直す
2. **ツール名の読み替え**: エージェント定義の `tools` は `mcp__claude_ai_Slack__*` / `mcp__zoho-mcp__*` に固定されている。コネクタの実名（`mcp__<uuid>__slack_*` 等）と合わないとプラグインのエージェント型は Slack を読めない。general-purpose に定義ファイルを読ませて代替する

## When to Use

- セッションを起動し直して、アラートの定期巡回を始めるとき
- 巡回ジョブが途切れた（一回きりジョブの登録が漏れた）ときの再開

## Instructions

### 1. 既存ジョブの確認

`CronList` で、プロンプトに `alert-patrol-loop` を含むジョブが既にないか確認する。
あれば二重登録になるので、`CronDelete` で消してから進む。

### 2. 次回分を登録する

`date '+%H %d %m'` で現在の時・日・月を取り、次の「HH:16」を求める（今が HH:16 以降なら次の時間。日・月の繰り上がりに注意）。

```
CronCreate(
  cron="16 <時> <日> <月> *",
  recurring=false,
  prompt="/home/m-uwaya/.claude/skills/alert-patrol-loop/resources/tick.md を Read して、その手順どおりに 1 回分の巡回を実行する（alert-patrol-loop）")
```

**`recurring: true` にしない。** 遅れの理由は Overview を参照。
cron のプロンプトにはファイル参照だけを書く。手順全文を書くと、登録のたびにメインの履歴に全文が積まれる。

### 3. 今すぐ 1 回実行する

`resources/tick.md` の Step 1 以降を実行する（Step 0 の次回登録は手順 2 で済んでいるので飛ばす）。

### 4. 報告

次回の実行時刻と、今回の巡回結果を 1〜2 行で報告する。

## Guidelines

- **1 日 1 回は `/clear` して、このスキルで張り直す。** 連鎖でも 1 回ごとに履歴が数 k トークン伸びる
- **セッションを閉じると止まる。** Splunk が社内ネットワークにあるため、クラウドの scheduled agent では代替できない
- プラグイン側のエージェント定義がコネクタの実名に追従したら、このスキルは不要になる。その場合は `triage-external-access-alert` の「定期実行とトークン運用」の手順に戻す
- 発報時刻が変わったら、`SKILL.md` と `resources/tick.md` の「16」を合わせて変える
