---
name: score-backlog
description: "status::backlog の issue を WSJF で採点し、Wiki の採点表・weight・カンバンボードの並び順を更新する。リファインメント前の実行と、会議後の乖離還元に使う"
---

# バックログ優先度スコアリング

## 概要

着手が決まっていない open issue を WSJF（`(アウトカム + 放置リスク + 運用効率) ÷ サイズ係数`）で採点し、Wiki の採点表・各 issue の weight・カンバンボードの並び順を更新する。

**対象は `status::backlog` だけではない。** `status::*` ラベルが無い open issue も含む（Step 2）。

PO が全件をゼロから検討する代わりに、たたき台の順位と根拠を用意する。PO は修正のみを行う。

## 使いどころ

- **リファインメント前（隔週）**: 新規 issue の採点と、weight が入った issue の再計算
- **会議で並び替えた後**: ボードの実順序と WSJF 順の乖離をスコアへ還元する（Step 3 のみ単独実行も可）
- **PO がスコアを直した後**: 採点表 Wiki のアウトカム・放置リスク・運用効率を PO が直接編集したら、Step 1 → 6 → 7 → 8 → 10 だけを回して順位・ボード・Artifact を追随させる。issue 本文の再読み込みは不要
- **採点基準を変更したとき**: 全件を再採点して順位を引き直す

## 対象

- Issue 管理: `eseikatsu/es-account/account-service`
- 採点基準: [Group Wiki `バックログ優先度づけ`](https://gitlab.com/groups/eseikatsu/es-account/-/wikis/%E3%83%90%E3%83%83%E3%82%AF%E3%83%AD%E3%82%B0%E5%84%AA%E5%85%88%E5%BA%A6%E3%81%A5%E3%81%91)
- 採点表: 同 Wiki の `バックログ優先度づけ/採点結果`
- 並び順: [カンバンボード 4911856](https://gitlab.com/groups/eseikatsu/es-account/-/boards/4911856)

## Step 1: 基準と前回結果を読む

採点基準と前回の採点結果を必ず先に読む。基準を記憶で代用しない。

```bash
G="groups/eseikatsu%2Fes-account"
RUBRIC="%E3%83%90%E3%83%83%E3%82%AF%E3%83%AD%E3%82%B0%E5%84%AA%E5%85%88%E5%BA%A6%E3%81%A5%E3%81%91"
glab api "$G/wikis/$RUBRIC" | jq -r '.content'
glab api "$G/wikis/$RUBRIC%2F%E6%8E%A1%E7%82%B9%E7%B5%90%E6%9E%9C" | jq -r '.content'
```

採点表は正本である。スクラッチパッドのファイルはセッション途中で消えるため、前回スコアはここから復元する。

**採点表への手編集は PO からの入力として尊重する。** アウトカム・放置リスク・運用効率・判定根拠が前回の生成物と違っていても、それは PO が事業側の文脈を反映した結果なので上書きしない。
事業側の文脈（営業からの要望の強度、経営方針、他部署との調整状況）は issue 本文に無く、機械の採点は必ず誤る。

判定根拠の先頭に次のマーカーがある行は、順位表から外して該当セクションへ移す。

| マーカー | 移動先 |
| --- | --- |
| `[クローズ推奨]` | クローズ推奨（「未整理Issueの評価」ページ） |
| `[情報不足]` | 情報不足（採点結果ページ） |

マーカーの付いた issue は WSJF を計算しない。GitLab 側のクローズは行わず、一覧の提示までにとどめる。

## Step 2: 対象を取得する

対象は **open かつ Milestone が付いていない issue のうち、`status::*` ラベルが無いもの、または `status::backlog` だけのもの**。

**`status::backlog` だけを引いてはいけない。** 母集団が数分の一になる。
2026-08-14 時点で `status::backlog` は 73 件、`status::*` ラベル無しは 545 件で、**後者が 9 割近くを占める**。
backlog だけで採点していた回は、統合後の上位 20 件のうち 11 件を取りこぼしていた（1 位の #3144 も含む）。

```bash
PROJ="eseikatsu%2Fes-account%2Faccount-service"
glab api --paginate "projects/$PROJ/issues?state=opened&per_page=100" | jq -s 'add' > all_open.json
jq '[.[] | (.labels | map(select(startswith("status::")))) as $s
     | select(.milestone == null)
     | select(($s|length) == 0 or ($s == ["status::backlog"]))]' all_open.json > target.json
jq 'length' target.json
```

**`glab api --paginate` はページごとに独立した JSON 配列を返す。** `jq -s 'add'` で結合しないと、後続の `jq` がページ単位の結果を並べて出す。件数が 100 単位で並んでいたら結合を忘れている。

除外の内訳を出して報告する。

```bash
jq -r '[.[] | (.labels | map(select(startswith("status::")))) as $s
        | if .milestone != null then "Milestone あり"
          elif ($s|length) > 0 and ($s != ["status::backlog"]) then "他の status ラベルあり"
          else "採点対象" end]
       | group_by(.) | map("\(.[0]): \(length) 件") | .[]' all_open.json
```

Milestone が付いた時点で着手が決まっているため対象から外す。`status::backlog` の外し忘れで Milestone 付きが混ざることがあるので、検出したらラベルを外すようリファインメントへ報告する。

`status::backlog` は「上位 20 件の着手候補」を指すラベルであって、採点対象の定義ではない（Step 9 参照）。

日本語を含むラベルを条件に使うときは URL エンコードする。生の日本語は HTTP 400 になる。

```bash
L=$(jq -rn '"effort::期日あり"|@uri')
glab api --paginate "projects/$PROJ/issues?labels=$L&state=opened&per_page=100"
```

## Step 3: 人が動かした順序をスコアへ還元する

**採点より先に必ず実行する。** 会議でドラッグした並び順は GitLab に保存されているが、このまま採点して整列すると WSJF 順で上書きされ、会議の結論が消える。

ボードの実順序を取得し、前回の採点表の順位と突き合わせる。

```bash
glab api --paginate "projects/$PROJ/issues?labels=status::backlog&state=opened&order_by=relative_position&sort=asc&per_page=100" \
  | jq -r '.[].iid' > actual_order.txt
```

**順位が 10 以上動いている issue を抽出し、一覧で PO に提示する。**「なぜ動かしたか」を確認し、その理由を 3 項目のどれかに反映してから Step 4 へ進む。

- 上へ動かした → アウトカムか放置リスクが過小評価だった可能性が高い
- 下へ動かした → 依存関係で着手できない、あるいは放置リスクの評価が過大だった可能性が高い

反映せずに進めると、次回も同じ議論を繰り返す。乖離が繰り返し起きる項目は個別の採点ミスではなく、採点基準の点数の目安が実態と合っていない証拠なので、採点基準自体を直す。

初回実行時や、前回整列から誰も動かしていない場合はこの Step を飛ばす。

## Step 4: 採点する

週次では前回採点日以降に更新された issue と新規の issue だけを再採点し、それ以外は前回の点数を引き継ぐ（詳細は採点基準の「毎回の採点範囲」）。
**初回実行時、前回の採点表が存在しない場合、採点基準を変更した場合は、差分採点を使わず全件を採点する。**

各 issue にアウトカム・放置リスク・運用効率をフィボナッチ（1,2,3,5,8,13）で付け、根拠として本文の該当箇所を引用する。

`description` は 1000〜1500 字に切り詰めて読む。全件を 3〜4 バッチに分けて読み、**全件を一度に相対比較してから採点する**。1 件ずつ順に採点すると後半で基準がずれる。

**採点しないもの**: 本文が空、テンプレートのまま、事象が未検証。`unscorable` として分離し、並び順では末尾に置く。weight 1 と組み合わさると根拠のないスコアが上位に紛れ込むため。

**前回から点数が動いた issue は理由を明示する**。書けない変動は基準の揺れなので差し戻す。

採点結果は次の形式の JSON にする。

```json
{
  "scored": [{"iid":4344,"oc":8,"nr":13,"oe":5,"why":"根拠","note":"任意の注記"}],
  "unscorable": [{"iid":4079,"reason":"本文がテンプレートのまま"}]
}
```

書いたら件数を検算する。

```bash
jq -r --slurpfile s scores.json '[.[].iid] - [$s[0].scored[].iid,$s[0].unscorable[].iid]|join(",")' backlog.json  # 漏れ
jq -r --slurpfile b backlog.json '[.scored[].iid,.unscorable[].iid] - [$b[0][].iid]|join(",")' scores.json          # 余り
```

## Step 5: weight を決める

- チームが設定済みの値があればそれを使う（下げない）
- 未設定は 1
- 明らかにボリュームが大きいものだけ 8 / 13

書き込みは未設定分のみ。差分一覧を提示して承認を得てから実行する。

```bash
glab api --method PUT "projects/$PROJ/issues/$IID?weight=$W"
```

失敗が出ることがあるので、成否を数えて失敗分はリトライする。

## Step 6: WSJF を計算する

`WSJF = (oc + nr + oe) / サイズ係数` を降順ソート。サイズ係数は weight を 3 段階に丸めた値。

| weight | サイズ | 係数 |
| --- | --- | ---: |
| 1 〜 2 | S | 1 |
| 3 〜 5 | M | 2 |
| 8 〜 13 | L | 4 |

同点は **放置リスクの高い順 → アウトカムの高い順 → iid 昇順** で割る。分子が整数和で分母が 3 種類しかないため同点は必ず多く出る。

**weight をそのまま分母にしない。** 2026-08-13 の採点では weight 2 以上の 15 件すべてが 47 位以下に固まり、weight を入れる動機が逆向きになっていた。
経緯と実測は採点基準の「weight とサイズ係数」にある。

計算とファイル生成は C# file-based apps で行う（`scripting-guide` スキル参照）。

**Native AOT では `JsonSerializer` の型推論版が使えない。** `Deserialize<T>` だけでなく `Serialize<T>`（`Serialize(文字列)` を含む）も実行時に落ちる。
入力は `JsonDocument` で読み、出力の文字列エスケープは自前の関数で行う。

**`dotnet run -` にコードを heredoc で渡すとき、入力ファイルを `<` で渡せない。** どちらも stdin を使うため衝突し、`The input does not contain any JSON tokens` で落ちる。
入力は `File.ReadAllText("<絶対パス>")` で読む。`dotnet run` の作業ディレクトリは呼び出し元と異なることがあるため、パスは絶対で書く。

出力するファイルは次の 4 つ。

| ファイル | 用途 |
| --- | --- |
| `table_rows.md` | Wiki 順位表の行（Step 7） |
| `top20.md` | 上位 20 件の表。`create-sprint-agenda` がそのまま埋め込む |
| `expected_order.txt` | 採点順の iid。Step 8 の照合に使う |
| `ranked.json` | Artifact のデータ（Step 10） |

## Step 7: Wiki を更新する

**`glab api -f content="@ファイル"` は使えない。** `@` のファイル読み込みが効かず、ファイルパス文字列がそのまま本文になる。必ず `--input` と Content-Type ヘッダを使う。

```bash
jq -Rs --arg t "バックログ優先度づけ/採点結果" '{title:$t, format:"markdown", content:.}' scores.md > body.json
glab api --method PUT "$G/wikis/$RUBRIC%2F%E6%8E%A1%E7%82%B9%E7%B5%90%E6%9E%9C" \
  -H "Content-Type: application/json" --input body.json
```

**送信後に必ず content の長さを検証する**。slug と title だけ見ても壊れているか分からない。

```bash
glab api "$G/wikis/<slug>" | jq -r '.content|length'
```

**採点表の 1 行目は `採点日: YYYY-MM-DD` にする。** 次回の差分採点がこの日付を起点にするため、書き忘れると全件採点に戻る。

採点表には順位・3 項目・weight・サイズ・WSJF・根拠に加え、次のセクションを含める。

- **期日ありリスト**（順位表より前に置く）: `effort::期日あり` かつ Due date のある issue を期日順に並べる。WSJF は規模で割るため、期限が確定していても規模が大きいと順位が下がり、順位表だけでは取りこぼす
- 情報不足（採点対象外）
- 重複が疑われる issue

## Step 8: ボードを整列する

`move_before_id` は Global ID（`id`）を渡す。iid ではない。上位から連鎖させる。

```bash
# rank 昇順の iid/gid を order.tsv に用意しておく
prev=""
while IFS=$'\t' read -r rank iid gid; do
  [ -z "$prev" ] && { prev="$gid"; continue; }
  glab api --method PUT "projects/$PROJ/issues/$iid/reorder?move_before_id=$prev"
  prev="$gid"
done < order.tsv
```

連鎖しているため 1 件でも失敗すると以降がその後ろに並ぶ。成否を数え、失敗した iid を記録する。
失敗分は `order.tsv` から直前の gid を引いて単独でリトライする。

```bash
PREV=$(awk -F'\t' -v t=4372 '$2==t{print prev} {prev=$3}' order.tsv)
glab api --method PUT "projects/$PROJ/issues/4372/reorder?move_before_id=$PREV"
```

実行後に照合する。Step 2 で除外した Milestone 付きの issue はレーンに残るため、照合時に差し引く。

```bash
glab api --paginate "projects/$PROJ/issues?labels=status::backlog&state=opened&order_by=relative_position&sort=asc&per_page=100" \
  | jq -r '.[].iid' | rg -v '^<除外した iid>$' | diff - expected_order.txt
```

ボードのソート設定が Manual でないと並び順は反映されない。

## Step 9: `status::backlog` を上位 20 件に絞る

`status::backlog` は「上位 20 件の着手候補」を指すラベルで、バックログレーンの見通しを一定件数に保つためのもの。
21 位以下から外しても採点表には全件が残り、次回も採点対象に含まれる。**ラベルを外すことは「やらない」判断ではない。**

**この Step は PO がスコアを妥当と判断してから実行する。** 順位が納得できない状態で絞ると、着手すべきものがレーンから消える。
実行前に対象件数を提示して承認を得る。

```bash
# 21 位以下からラベルを外す
glab api --method PUT "projects/$PROJ/issues/$IID?remove_labels=status::backlog"
```

外した issue は status ラベルが無い状態になり、採点基準上は引き続き採点対象（「status ラベルがないか `status::backlog` だけのもの」）である。
Step 2 の取得クエリは `status::backlog` で引いているため、**絞り込みを実施した次回以降は取得条件を「Milestone なし かつ status ラベルなし または `status::backlog`」に広げる必要がある**。

## Step 10: Artifact で可視化する

順位・3 軸の積み上げバー・根拠・情報不足・重複疑いを載せる。会議でボードと並べて見る資料。

**新規に発行せず、既存の Artifact を上書きする。** URL は採点基準 Wiki の成果物表に記載されており、`Artifact` ツールの `url` パラメータに渡す。

配色は `dataviz` スキルのカテゴリカル 3 スロット（青 / 橙 / 緑）を使い、バリデータを通してから確定する。

## 落とし穴

- **人が動かした順序は採点前に還元する**（Step 3）。後回しにすると整列で会議の結論が消える
- スクラッチパッドのファイルはセッション途中で消えることがある。**正本は Wiki に置き、消えたら Wiki から復元する**
- `glab api -f content="@file"` は無言で壊れる（Step 7 参照）
- **`status::backlog` だけを引くと母集団が 1 割強になる。** status ラベルの無い open issue が本体（Step 2）
- `glab api --paginate` はページごとに別々の JSON 配列を返す。`jq -s 'add'` で結合する（Step 2）
- Milestone 付きの issue に `status::backlog` が残っていることがある。採点対象から外す（Step 2）
- 日本語を含むラベルは URL エンコードしないと HTTP 400 になる（Step 2）
- `dotnet run - << 'EOF'` と `< input.json` は併用できない。入力はファイルパスで読む（Step 6）
- Native AOT では `JsonSerializer.Serialize` も落ちる。`Deserialize` だけの話ではない（Step 6）
- `reorder` は連鎖するため 1 件の失敗が以降の並びをずらす。成否を数えて失敗分をリトライする（Step 8）
- 採点表の `採点日:` を書き忘れると次回が全件採点に戻る（Step 7）
- ラベル（`priority::*` / `effort::*`）はこの運用では更新しない
- 放置リスクは期限までの距離を含む。期限が確定していても遠ければ 13 にしない
- 事業側の文脈（営業からの要望強度、経営方針、他部署との調整状況）は issue 本文にないため必ず誤る。PO の修正を仰ぐ
