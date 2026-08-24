---
name: record-sprint-plan
description: "スプリントプランニングで決めた担当割り当てを議事録に記録し、Milestone を割り当てた issue の status を To Do に揃える。MTG 直後に実行する"
---

# スプリントプランニング 計画記録

## 概要

会議で決めた担当割り当てを議事録の `# 担当割り当て` 節に書き込み、次回の振り返りの基準にする。
あわせて Milestone を割り当てた issue の status を `To Do` へ揃える。

`create-sprint-agenda` と対で動く。**この記録がなければ次回の達成状況を集計できない。**

## 対象

| | |
| --- | --- |
| 議事録 | DocBase、当日のスプリントプランニング記事 |
| Issue 管理 | `eseikatsu/es-account/account-service`、Milestone は `[ESA]` と `[LS]` |

Square（`eseikatsu/es-square`）は記録の対象外とし、議事録にはボードへのリンクだけを残す。
振り返りの集計範囲を es-account に揃えるため。

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
for M in "%5BESA%5D2026_09_08" "%5BLS%5D2026_09_08"; do
  glab api --paginate "projects/$PROJ/issues?milestone=$M&per_page=100"
done | jq -s 'add' > planned.json
```

担当者ごとに集計する。未アサインは別枠に出す。

```bash
jq -r 'group_by(.assignee.username // "未アサイン")[]
  | "\(.[0].assignee.username // "未アサイン")\t\(length)件\tweight=\([.[].weight // 0] | add)"' planned.json
```

## Step 3: status を To Do に揃える

Milestone が割り当てられた **open の** issue は着手を決めたものなので、status を `To Do` に統一する。

closed は対象外。完了した issue から status ラベルを外す運用のため、ラベルなしの closed に `To Do` を付けると完了済みのものが未着手に見える。

| 現在の status | 操作 |
| --- | --- |
| `backlog` / ラベルなし / `リファインメント済` | `To Do` へ付け替える |
| `To Do` 以降（`Doing` 等） | 変更しない |

**前進側への一方向のみ。** 既に着手している issue の状態を巻き戻さない。

```bash
glab api --method PUT "projects/$PROJ/issues/$IID" -f "add_labels=status::To Do" -f "remove_labels=status::backlog"
```

`labels` パラメータは使わない。全置換になり `type::` や `priority::` が消える。

対象の一覧を提示して承認を得てから実行する。実行後に件数を照合する。

この処理により、Milestone 付きの `status::backlog` が構造的に発生しなくなる。
`score-backlog` は採点対象を「Milestone なし」に限定しているため、両者が揃ってはじめてラベルの意味が一意になる。

## Step 4: 議事録に記録する

`# 担当割り当て` 節を次の形式で置き換える。

```markdown
# 担当割り当て

対象 Milestone: `[ESA]2026_09_08` / `[LS]2026_09_08`

## 上屋 誠 (makoto.uwaya)

| issue | タイトル | W | status |
| --- | --- | ---: | --- |
| [#4417](https://gitlab.com/eseikatsu/es-account/account-service/-/issues/4417) | 宅建業者情報の Zoho 連携 | 3 | To Do |

合計 weight: 10
```

`patchPostBody` で該当節だけを差し替える。全文を送り直さない。
失敗する場合のみ `updatePost` で body 全体を更新する。

**書き込み後、必ず記事を取得して `#\d+` の件数が Step 2 の総数と一致することを確認する。**
次回の `create-sprint-agenda` はこの節をパースするため、欠けると差分が誤る。

## 落とし穴

- 見出しは `# 担当割り当て` から変えない。次回のパース対象
- 表の体裁が崩れても `#\d+` さえ残っていれば突合できる。issue リンクを必ず含める
- status の付け替えは前進側のみ。`Doing` を `To Do` に戻さない（Step 3）
- ラベル更新に `labels` を使わない。`add_labels` / `remove_labels` を使う
- 未アサインの issue も記録する。次回「誰も手を付けなかった」ことが見える
- 記事が draft のままでも記録してよい。公開は PO の操作
