---
name: create-sprint-agenda
description: "週次スプリントプランニングのアジェンダを DocBase に作成する。前回計画との差分を集計し、バックログを整理して会議資料を用意する。MTG 前日に実行する"
---

# スプリントプランニング アジェンダ作成

## 概要

前回議事録に記録された担当割り当てと GitLab の現在状態を突き合わせ、達成状況を集計する。
あわせてバックログを整理し、アジェンダを DocBase に draft で作成する。

会議後の記録は `record-sprint-plan` が行う。**この 2 つは対で動く。**片方だけを使うと次回の振り返りが空になる。

## 対象

| | |
| --- | --- |
| 議事録 | DocBase、グループ `Square`(29850) / `社員公開`(27865)、タグ `議事録` |
| Issue 管理 | `eseikatsu/es-account/account-service`、Milestone は `[ESA]` と `[LS]` |
| バックログ | `score-backlog` スキルに委譲 |
| テンプレート | `{skill_base_dir}/templates/agenda.md` |

会議は毎週木曜。Milestone は約 4 週なので、**両者の周期は一致しない**。
達成状況は Milestone 単位ではなく、前回議事録のスナップショットとの差分で出す。

## Step 1: 前回議事録を取得する

```
searchPosts(query: "title:スプリントプランニング desc:published_at", perPage: 5)
searchPosts(query: "title:スプリントプランニング is:draft desc:changed_at", perPage: 5)
```

**draft は既定の検索結果に含まれない。** 前回分が未公開のまま残っていることがあるため、両方を引いて会議日が直近のものを選ぶ。

選んだ記事を `getPost` で取得し、本文をファイルに落としてから担当割り当ての節だけを切り出す。

**本文全体から `#[0-9]+` を拾ってはいけない。** 議事録にはバックログ上位 20 件の issue 番号も載っており、節を切らずに抽出すると前回計画に 20 件混入する。

```bash
sed -n '/^# 担当割り当て/,$p' prev_post.md > prev_section.md
[ -s prev_section.md ] || sed -n '/^# プランニング/,/^# 担当割り当て/p' prev_post.md > prev_section.md
rg -o '#([0-9]+)' -r '$1' prev_section.md | sort -u > prev_iids.txt
wc -l prev_iids.txt   # 担当者ごとの表の件数合計と一致するか目視する
```

`# 担当割り当て` 節が無い議事録もある。`record-sprint-plan` を通さず手で書いた回は担当割り当てが `# プランニング` 節に入っているため、**そちらもフォールバックとして見る**（2026-08-06 の議事録が該当）。

どちらの節も無い場合だけ初回として扱い、Step 2 を飛ばして振り返り節に「前回の担当割り当ての記録がないため、次回から集計する」と書く。

## Step 2: 前回計画と現在を突合する

```bash
PROJ="eseikatsu%2Fes-account%2Faccount-service"
for M in "%5BESA%5D2026_08_25" "%5BLS%5D2026_08_25"; do
  glab api --paginate "projects/$PROJ/issues?milestone=$M&per_page=100"
done | jq -s 'add' > current.json
```

Milestone 名は Step 3 で決めた**現スプリント**のもの（次期ではない）。

各 issue を 6 区分に振り分ける。判定は上から順に当てる。

| 区分 | 判定 |
| --- | --- |
| 却下（未実施） | `却下` ラベルが付いている |
| 完了 | `state=closed`、または status が `Done` / `本番適用待ち` / `テスト完了` / `品検待ち` / `ステージングアップ待ち` |
| 進行中 | status が `Doing` / `MR` / `検証中` / `Feedback` |
| 未着手 | status が `To Do` / `リファインメント済` |
| 中止・除外 | `prev_iids.txt` にあるが現在 Milestone から外れた、または `status::backlog` へ戻った |
| 追加・割り込み | `prev_iids.txt` になく現在 Milestone にある |

**`却下` を完了に数えない。** 却下した issue は close されるため closed 判定では完了に混ざるが、実施していないのでベロシティには入らない。
`却下` は `status::` 接頭辞を持たない単独ラベルなので、status ラベルの走査では拾えない。判定順を closed より先に置く。

```bash
jq -r '.[] | select([.labels[]] | any(. == "却下")) | "#\(.iid)\t\(.title)"' current.json
```

**closed だけを完了にしない。** MR マージ時に `status::ステージングアップ待ち` へ移す運用があり、開発としての完了はその時点で到達している。closed 基準ではベロシティが実績の数分の一に見える。

ベロシティは完了区分の weight 合計。却下は含めない。

さらに**完了区分には前回スナップショット時点で既に完了へ到達していたものが含まれる**。
分離しないとベロシティが実態より大きく見える。前回の status を突合表に持ち、次の 2 つを併記する。

- 完了 weight 合計（現在の到達点）
- そのうち前回時点で未完了だったものの weight 合計（この 1 週間の増分）

2026-08-13 の実行では完了 32 件 / weight 30 のうち 17 件 / weight 17 が前回時点で既に到達済みで、増分は 15 件 / weight 13 だった。

集計表と、区分ごとの明細（issue リンク・タイトル・担当・weight）を作る。
中止・除外には**理由を書く欄を空で置く**。会議で埋めるため。

**追加・割り込みに発生源の欄は置かない。** 会議で埋める運用にしたが使われなかった。
件数と weight、および内容の傾向（CI 系・機能系などの内訳）だけを示す。

## Step 3: Milestone を決める

```bash
G="groups/eseikatsu%2Fes-account"
glab api "$G/milestones?state=active" | jq -r '.[] | "\(.title)\t\(.start_date)\t\(.due_date)"'
glab api "groups/eseikatsu%2Fes-square/milestones?state=active" | jq -r '.[] | "\(.title)\t\(.due_date)"'
```

現スプリント（Step 2 用）は due_date が実行日以降で最も近いもの、次スプリント（テンプレート用）はその次。

テンプレートに埋めるのは URL エンコード済みの文字列。

```bash
jq -rn --arg t "[ESA]2026_09_08" '$t|@uri'   # %5BESA%5D2026_09_08
```

Square は命名規則が異なる（`[Square]20260826`）。ESA / LS のパターンで推測せず、必ず API の結果から取る。

**次期の Square Milestone が未作成のことがある。** Square は ESA / LS と作成タイミングが違うため、`state=active` に現行分しか出てこない回がある。
その場合は現行を `{{MS_SQUARE}}` に入れ、アジェンダの Square 節に「次期 Milestone は未作成。この場で作成してからリンクを張り替える」と明記する。次期の名前を推測して URL を組まない。

## Step 4: バックログを整理する

`score-backlog` スキルを実行する。差分採点・ラベル運用・ボード整列・Artifact 更新まで含まれる。

完了後、上位 20 件を取り出してアジェンダに埋め込む。

```markdown
| # | issue | WSJF | 判定根拠 |
```

出所は `score-backlog` の Step 6 が出力する `top20.md`。

**生成したファイルの中身を読み、その文字列をそのまま使う。** 記憶で書き直さない。
issue のタイトルと判定根拠は本文を読まなければ書けない情報であり、書けてしまう場合は捏造している。

採点表の列は `# | issue | 種別 | アウトカム | 放置リスク | 運用効率 | weight | WSJF | 判定根拠` の 9 列。
WSJF が 8 列目、判定根拠が 9 列目。

**`sed` の後方参照で列を並べ替えない。** 後方参照は `\9` までで、`\10` は「`\1` の後に文字 `0`」と解釈される。
9 列目を `\10` で拾うと判定根拠の欄に「順位 + 0」が入り、`60` `120` のような数字が並ぶ。2026-08-13 の実行で実際に踏んだ。

列の切り出しは `awk` で行う。

```bash
rg -N '^\| [0-9]+ \| \[#' prev_scores.md | awk -F' *\\| *' '{
  match($3, /#[0-9]+/); iid = substr($3, RSTART + 1, RLENGTH - 1)
  wsjf = $9; gsub(/\*/, "", wsjf)
  print $2"\t"iid"\t"$4"\t"$5"\t"$6"\t"$7"\t"$8"\t"wsjf"\t"$10
}' > prev_rank.tsv
```

`awk -F' *\\| *'` では行頭の `|` で `$1` が空になるため、**論理列 N は `$(N+1)`** になる。
抽出後、判定根拠の欄が日本語の文になっているかを先頭数行で目視する。数字が入っていたら列がずれている。

`score-backlog` は PO の承認を求める箇所があるため、この Step は対話が挟まる。
アジェンダ作成をまとめて流したい場合でも、ここは飛ばさない。

## Step 5: アジェンダを組み立てる

テンプレートを読み、プレースホルダを置換する。

| プレースホルダ | 値 |
| --- | --- |
| `{{RETROSPECTIVE}}` | Step 2 の集計表と明細 |
| `{{BACKLOG}}` | Step 4 の上位 20 件 |
| `{{COST_END}}` | 実行日（`YYYY-MM-DD`）。`startDate` / `from` の `2026-04-01` は年度始まりなので固定 |
| `{{MS_ESA}}` `{{MS_LS}}` `{{MS_SQUARE}}` | Step 3 の次スプリント（URL エンコード済み） |

置換後、`{{` が残っていないか検査する。

```bash
rg -n '\{\{' agenda_filled.md && echo "未置換あり"
```

## Step 6: DocBase に作成する

```
createPost(
  title: "YYYY/MM/DD Square 物件検索/メッセージ/アカウントサービス/ライセンスサーバ スプリントプランニング",
  body: <Step 5 の本文>,
  draft: true,
  scope: "group",
  groupIds: [29850, 27865],
  tags: ["議事録"]
)
```

日付は会議日（実行日の直近の木曜）。引数で指定があればそれを使う。

**draft のまま残す。** 公開は PO の操作とする。

作成後、記事 URL と、会議で確認すべき点（中止・除外の理由、追加・割り込みの発生源）を報告する。

## 落とし穴

- **生成物を記憶で書き直さない**（Step 4）。issue のタイトルと根拠は読まなければ書けない。書けたなら捏造している
- 本文を DocBase へ送る前に、先頭と末尾の 1 行を確認する。混入した 1 文字が記事の先頭に残る
- `searchPosts` の既定結果に draft は含まれない。`is:draft` の検索を併用する（Step 1）
- 前回議事録の担当割り当ては `# 担当割り当て` に無いことがある。`# プランニング` 節もフォールバックで見る。どちらも無いときだけ初回扱いにして黙って進めない（Step 1）
- 本文全体から issue 番号を拾うとバックログ上位 20 件が混入する。節を切り出してから抽出する（Step 1）
- 完了判定を closed に置かない。`ステージングアップ待ち` 以降を完了とする（Step 2）
- `却下` ラベルの issue は closed だが未実施。完了と分けてベロシティから除く（Step 2）
- 表の列を `sed` の後方参照で並べ替えない。`\10` は `\1` + `0` になる（Step 4）
- 日本語を含むラベルで `glab api "...?labels=..."` を叩くと HTTP 400 になる。`jq -rn '"effort::期日あり"|@uri'` でエンコードする
- `createPost` は本文をインラインでしか受け取れない。生成物の読み込みと送信で本文がコンテキストに 2 回載るため、明細表を厚くするほど実行コストが上がる
- 一部だけ直すなら `patchPostBody` を使う。ただし**ローカルのファイルと投稿本文で行番号がずれる**（節を差し替えるスクリプトが空行を 1 行増減させるなど）。`oldContent` が 1 文字でも違うと 409 になるので、**1 行だけを同内容で置換する試験パッチでオフセットを確認してから**本番のパッチを送る
- Square の Milestone は命名規則が異なる。API の結果から取る（Step 3）
- 画像は貼らない。ロードマップも SendGrid も URL リンクにする。前回の議事録を複製する運用では古い画像が残り続けた
- コスト URL の `startDate` / `from` は年度始まり固定。`endDate` / `to` だけを動かす
