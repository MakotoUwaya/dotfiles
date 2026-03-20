---
name: splunk-spl-formatter
description: Splunk の SPL クエリや Dashboard XML 内の SPL を整形する。改行位置の最適化、XML エスケープ、サブサーチのインデントを統一する。「SPL 整形」「ダッシュボード修正」「Splunk フォーマット」で使用。
---

# Splunk SPL Formatter

## Overview

Splunk の SPL（Search Processing Language）クエリを、可読性の高い一貫したスタイルに整形する。
Dashboard XML 内の `<query>` タグに埋め込まれた SPL にも対応する。

## When to Use

- SPL クエリの改行位置がバラバラで読みにくい時
- Splunk Dashboard XML の SPL を整形・修正する時
- 新規 SPL を作成してフォーマットを統一したい時

## Instructions

### 1. 基本ルール: パイプコマンド単位で改行

各 `| command` を1行にまとめる。コマンド内で不要な改行をしない。

**NG（コマンド内で改行）:**
```spl
| eval x_cli_cmd_param=urldecode(x_cli_cmd_param),
x_cli_chohyo_shubetsu=urldecode(x_cli_chohyo_shubetsu),
category=urldecode(category)
```

**OK（1行にまとめる）:**
```spl
| eval x_cli_cmd_param=urldecode(x_cli_cmd_param), x_cli_chohyo_shubetsu=urldecode(x_cli_chohyo_shubetsu), category=urldecode(category)
```

### 2. 複数フィールド設定の eval も1行

`| eval` で `cmd_type=case(...), cmd_name=case(...), cmd_param=case(...)` のように複数フィールドを同時設定する場合も、1つの `| eval` として1行にまとめる。

### 3. サブサーチ（join / append 等）のインデント

サブサーチ `[search ...]` 内のパイプコマンドは **4スペースインデント** で改行する。

```spl
| join type=left key1, key2 [search index="..." sourcetype="..."
    | eval field1=...
    | eval field2=...
    | stats latest(_time) as last_time by field1, field2
    | fields field1, field2, last_time]
```

### 4. 検索条件（index 行）

`index=... sourcetype=... (条件)` は極力1行にまとめる。

### 5. XML 内の SPL エスケープ

Dashboard XML の `<query>` 内では以下のエスケープが必要:

| 文字 | エスケープ |
|------|-----------|
| `<`  | `&lt;`    |
| `>`  | `&gt;`    |
| `&`  | `&amp;`   |

正規表現の名前付きキャプチャ `(?<name>...)` は `(?&lt;name&gt;...)` になる。
`case()` 内の `>=` は `&gt;=` になる。

### 6. 代入の空白

`=` の前後にスペースを入れない（Splunk の慣例）。

```spl
| eval field=value          ✅
| eval field = value        ❌
```

### 7. クリップボードコピー

整形結果をユーザーに渡す際は、WSL2 環境のクリップボードコピーを使用する（clipboard ルール参照）。

## Examples

### Before (整形前)
```spl
index="myindex" sourcetype="mylog"
method=GET
| eval field1=urldecode(field1),
field2=urldecode(field2)
| lookup my_lookup.csv key OUTPUT
value1, value2
| stats count by
field1, field2
| table field1,
field2, count
```

### After (整形後)
```spl
index="myindex" sourcetype="mylog" method=GET
| eval field1=urldecode(field1), field2=urldecode(field2)
| lookup my_lookup.csv key OUTPUT value1, value2
| stats count by field1, field2
| table field1, field2, count
```

## Guidelines

- 行の長さに厳密な上限は設けない（SPL は横に長くなることを許容する）
- ただし、Dashboard XML 内では `<query>` タグのインデント分を考慮する
- `| command` の前に適切なインデントを入れて、メインサーチとサブサーチの階層を明確にする
- 元の SPL のロジック（フィールド名、条件、順序）は一切変更しない — フォーマットのみ変更する
