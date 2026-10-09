---
name: record-sprint-plan
description: "スプリントプランニングで決めた担当割り当てを議事録の担当割り当て節に記録し、次回の振り返りの基準にする。MTG 直後に実行する"
---

# スプリントプランニング 計画記録

## 概要

会議で決めた担当割り当てを議事録の `# 担当割り当て` 節に書き込み、次回の振り返りの基準にする。

`create-sprint-agenda` と対で動く。**この記録がなければ次回の達成状況を集計できない。**

## 対象

| | |
| --- | --- |
| 議事録 | DocBase、当日のスプリントプランニング記事 |
| Issue 管理 | `eseikatsu/es-account/account-service`、Milestone は `[ESA]` と `[LS]` |

## Step 1: 対象議事録を特定する

当日の記事を探す。draft のことが多いため両方を引く。

```
searchPosts(query: "title:スプリントプランニング is:draft desc:changed_at", perPage: 5)
searchPosts(query: "title:スプリントプランニング desc:published_at", perPage: 5)
```

会議日がタイトルと一致するものを選ぶ。複数該当したら PO に確認する。

## Step 2: 割り当てを取得する

新スプリントの Milestone 配下を取得する。

```bash
PROJ="eseikatsu%2Fes-account%2Faccount-service"
for M in "%5BESA%5D2026_10_27" "%5BLS%5D2026_10_27"; do
  glab api --paginate "projects/$PROJ/issues?milestone=$M&per_page=100"
done | jq -s 'add' > planned.json
```

担当者ごとに集計する。未アサインは別枠に出す。

```bash
jq -r 'group_by(.assignee.username // "未アサイン")[]
  | "\(.[0].assignee.username // "未アサイン")\t\(length)件\tweight=\([.[].weight // 0] | add)"' planned.json
```

担当が複数いる issue は先頭の担当者の表に置き、タイトルの後ろに「（藤田篤史と共同）」のように残りの担当を書く。
別の担当者の表に重複して載せない。次回の突合で件数が二重になる。

## Step 3: 議事録に記録する

`# 担当割り当て` 節を次の形式で置き換える。

```markdown
# 担当割り当て

対象 Milestone: `[ESA]2026_10_27` / `[LS]2026_10_27`（2026-10-07 〜 10-27）

49 件 / weight 50 です。

## 上屋 誠 (makoto.uwaya)

| issue | タイトル | MS | W | status |
| --- | --- | --- | ---: | --- |
| [#4685](https://gitlab.com/eseikatsu/es-account/account-service/-/work_items/4685) | Slack 通知用の Bot トークンをリポジトリから外してシークレットで管理し、旧トークンを失効させる | ESA | 1 | To Do |

合計 weight: 9
```

担当者の節は ESA → LS の順に issue 番号の降順で並べる。weight 未設定の issue は W 列を `—` にし、合計の後ろに「（上記のうち 1 件は weight 未設定）」と添える。
会議後に GitLab 上で直接動かしたもの（Milestone の付け外し・却下・改名など）があれば、件数の行の下に 1 行ずつ残す。
ここに Milestone 外の issue 番号を書かない（落とし穴を参照）。

`patchPostBody` で該当節だけを差し替える。全文を送り直さない。
失敗する場合のみ `updatePost` で body 全体を更新する。

**書き込み後、必ず記事を取得して `#\d+` の件数が Step 2 の総数と一致することを確認する。**
次回の `create-sprint-agenda` はこの節をパースするため、欠けると差分が誤る。

## 落とし穴

- 見出しは `# 担当割り当て` から変えない。次回のパース対象
- 表の体裁が崩れても `#\d+` さえ残っていれば突合できる。issue リンクを必ず含める
- この節に Milestone 外の issue 番号を書かない。注記で他の issue に触れると次回の前回計画に混入する。必要なら番号を出さずに書く
- 共同担当の issue を複数の表に載せない（Step 2）
- 未アサインの issue も記録する。次回「誰も手を付けなかった」ことが見える
- 記事が draft のままでも記録してよい。公開は PO の操作
