---
name: docbase-markdown
description: DocBase のメモ・記事を作成・更新・コメントする際に自動適用される Markdown 記法ルール。MCP ツール (mcp__docbaseMcp__createPost, mcp__docbaseMcp__updatePost, mcp__docbaseMcp__createComment) で本文を書く前に必ずこのスキルを参照すること。
user-invocable: false
---

# DocBase Markdown 記法ルール

## Overview

DocBase 固有の Markdown 記法（独自拡張・HTML 装飾・数式・PlantUML・Mermaid）のリファレンス。

## When to Use

- DocBase にメモ・記事を作成・更新・コメントする際
- MCP ツール（createPost, updatePost, createComment）で本文を組み立てる前

DocBase は CommonMark 準拠 + 独自拡張の Markdown を採用している。

## Guidelines

- 本文の1行目にタイトルと同じ見出しを絶対に書かない
- 図表はテキスト罫線文字（`┌─┐│└` 等）ではなく Mermaid 記法を使う（DocBase での表示崩れ防止）
- 参考資料等の URL リンクを記載・更新する際は、`curl -sL <URL>` でページを取得し以下を検証する
  - リンクテキストとページの実際の `<title>` が一致しているか
  - 引用したページの内容が記事の文脈に対して妥当か（リンク切れ・内容変更の検出）

---

## 投稿時のグループ・タグルール

### グループ選択（社員公開系）

「社員公開」グループは文書の役割に応じて3つに分かれている。投稿時は文書の性質に応じて適切なグループを選択すること。

| グループ | ID | 用途 | 対象文書 |
|---------|-----|------|---------|
| 社員公開_ナレッジ | 53610 | ストック情報の蓄積。検索・AI参照の対象 | ルール・手順・知見・マニュアル・FAQ・技術解説 |
| 社員公開_周知 | 53611 | 全社員への周知。Slack `#announce_docbase全社周知` に通知される | 全員が読むべき重要なお知らせ・変更通知 |
| 社員公開 | 27865 | リンクを知る人向けの社外秘フロー情報 | 議事録・一時的な連絡・個人メモなど |

- 部門グループ（いい物件営業支援、仲介ソリューション本部 等）との併用可
- 迷った場合は「社員公開」を選択（最も制約が少ない）

### 優先タグ（必須）

**すべての投稿に、以下の優先タグから必ず1つ以上を付けること。**

| 優先タグ | 含むもの |
|---------|---------|
| ふりかえり | KPT・ポストモーテム・スプリントレビュー等 |
| 議事録 | 会議・打合せ・イベントの記録（振り返りを除く） |
| 企画・計画 | 計画・提案・戦略・設計構想 |
| 研修・学習資料 | 教材・勉強会・講義/LT資料・演習 |
| 手順・マニュアル | 手順・ルール/規程・ガイドライン・使い方 |
| 報告・お知らせ | 状況/結果の報告・周知・日報・リリース告知・障害報告 |
| ナレッジ・調査 | 知見・FAQ・技術解説・やってみた・事例・調査/分析 |
| index | 文書の一覧・リンク集 |
| 雑記・その他 | 上記いずれにも当てはまらない・個人メモ・自己紹介など |

- 優先タグに加えて、部門やプロダクト固有のローカルタグを自由に追加してよい
- AI タグ生成機能は停止されているため、タグは手動で付与すること

---

## DocBase 独自拡張（標準 Markdown にない機能）

### 差し込み機能（メモの引用・埋め込み）

```
#{メモID}
#{メモURL}
```

- **必ず前後に改行が必要**（インラインでは使えない）

```markdown
<!-- OK -->
前のテキスト

#{12345}

後のテキスト

<!-- NG: すべて動作しない -->
前のテキスト #{12345} 後のテキスト
前のテキスト #{12345}
#{12345} 後のテキスト
```

### 画像サイズ指定

画像サイズは HTML の img タグを使って、横幅100%表示にする(auto にしない)

```
# Bad
![image.png](https://image.docbase.io/uploads/b0943c6b-ae3e-4eb0-82c8-60:0d72c7e13d.png =WxH)

# Good
<img src="https://image.docbase.io/uploads/b0943c6b-ae3e-4eb0-82c8-600d72c7e13d.png" width=100%>
```

使うことは少ないが、一応公式のサイズ指定方法は以下の通り。  
印刷時に横幅以上に拡がってしまうので、「幅自動」は使いにくい。  
URL の後に半角スペース + `=幅x高さ` で指定。`x` は半角アルファベット。

```markdown
![](画像URL =100x100)  <!-- 幅100px × 高さ100px -->
![](画像URL =100x)     <!-- 幅100px、高さ自動 -->
![](画像URL =x100)     <!-- 幅自動、高さ100px -->
![](画像URL =full)     <!-- フルサイズ表示 -->
```

### コードブロックにファイル名

言語指定の後に `:ファイル名` を付ける。

````markdown
```ruby:sushi.rb
def sushi
  puts 'お寿司'
end
```
````

### テンプレート変数

メモのテンプレート機能で使用可能:

```
%{Year}  %{month}  %{day}  %{name}
```

調整: `%{Year:+1y}` で翌年

---

## HTML タグによる装飾

### 文字色・サイズ

```markdown
<span style="color:green;">緑のテキスト</span>
<span style="font-size:150%;">大きいテキスト</span>
```

### 下線

```markdown
<u>下線テキスト</u>
```

### ハイライト

```markdown
<mark>ハイライトテキスト</mark>
```

### 折りたたみ

```markdown
<details>
<summary>詳細を見る</summary>

- 寿司
  - エンガワ
  - 炙りサーモン

</details>
```

`<summary>` と内容の間に空行を入れると Markdown が正しくレンダリングされる。

---

## 数式（MathJax / TeX 記法）

### ブロック数式

コードブロックの言語指定を `math` にする:

````markdown
```math
\begin{equation}
E = mc^2
\end{equation}
```
````

### 1行数式

```markdown
$$ e^{i\theta} = \cos\theta + i\sin\theta $$
```

### インライン数式

```markdown
$ e^{i\theta} = \cos\theta + i\sin\theta $
```

### 注意: `_` のエスケープ

数式内の `_` が Markdown の斜体と認識される場合がある。`\_` にエスケープすること。

```markdown
<!-- NG --> $E'_R$, $E'_G$
<!-- OK --> $E'\_R$, $E'\_G$
```

---

## PlantUML

DocBase ではコードブロックの言語指定を **`uml`** にすると PlantUML が描画される（`plantuml` ではない）。

````markdown
```uml
@startuml
Alice -> Bob : こんにちは
@enduml
```
````

- 図の種類ごとに開始・終了タグが異なる:
  - UML 図全般: `@startuml` / `@enduml`
  - マインドマップ: `@startmindmap` / `@endmindmap`
  - ガントチャート: `@startgantt` / `@endgantt`
  - ワイヤーフレーム: `@startsalt` / `@endsalt`

---

## チェックボックスの注意点

半角の `(` が続く場合、`\` でエスケープが必要:

```markdown
- [ ] \(abc)
```

---

## Mermaid 図表

コードブロックの言語指定を `mermaid` にする。DocBase 固有の注意点のみ記載。

### DocBase 固有の注意点

- DocBase の Mermaid バージョンが最新でない場合があり、新しい構文が使えないことがある
- コードブロックの前後に**空行を入れる**とレンダリングが改善することがある
- 非常に複雑な図はレンダリングに失敗するため、適切に分割する
- 日本語ラベルで問題が出る場合は引用符（`"`）で囲む

### architecture-beta（アーキテクチャダイアグラム）

比較的新しい図表タイプ。独特の構文を持つ。

````markdown
```mermaid
architecture-beta
    group api(cloud)[API Layer]
    group app(server)[Application Layer]

    service web(internet)[Web Client]
    service gateway(cloud)[API Gateway] in api
    service auth(server)[Auth Service] in app

    web:R --> L:gateway
    gateway:B --> T:auth
```
````

- **group**: `group {id}({icon})[{title}] (in {parent})?`
- **service**: `service {id}({icon})[{title}] (in {parent})?`
- **edge**: `{serviceId}:{T|B|L|R} --> {T|B|L|R}:{serviceId}`
- **junction**: `junction {id} (in {parent})?` - エッジの分岐点
- **デフォルトアイコン**: `cloud`, `database`, `disk`, `internet`, `server`
- **拡張アイコン**: iconify-json/logos が利用可能
