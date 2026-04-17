---
name: excel-diff
description: 2つのExcelファイル(.xlsx)をセル単位で比較し差分を表示する。MRレビューでExcelのバイナリ差分を確認したい時、Excelファイルの変更前後を比較したい時に使用。「Excel 比較」「xlsx 差分」「Excel diff」で呼び出し。
---

# Excel Diff - Excel ファイル差分比較

## Overview

2つの Excel ファイル(.xlsx)を ClosedXML でセル単位に比較し、差分を人間が読める形式で出力する。
Git 上のバイナリ差分では内容を確認できない Excel ファイルのレビューに使用する。

## When to Use

- GitLab MR / GitHub PR で Excel ファイルが変更されている場合のレビュー
- 2つの Excel ファイルの差分を確認したい場合
- トリガー: 「Excel 比較」「xlsx 差分」「Excel diff」「Excel レビュー」

## Instructions

### 1. 比較対象ファイルの準備

MR レビューの場合は、変更前後のファイルをダウンロードする:

```bash
# GitLab の例
mkdir -p /tmp/excel-diff
glab api "projects/<encoded-path>/repository/files/<encoded-file-path>/raw?ref=<target-branch>" --method GET > /tmp/excel-diff/before.xlsx
glab api "projects/<encoded-path>/repository/files/<encoded-file-path>/raw?ref=<source-branch>" --method GET > /tmp/excel-diff/after.xlsx
```

### 2. C# スクリプトで差分比較を実行

scripting-guide に従い、C# + ClosedXML でパイプ実行する:

```bash
dotnet run - -- "<before.xlsx の Windows パス>" "<after.xlsx の Windows パス>" << 'CSEOF'
#:package ClosedXML@0.104.1

using ClosedXML.Excel;

var beforePath = args[0];
var afterPath = args[1];

using var wbBefore = new XLWorkbook(beforePath);
using var wbAfter = new XLWorkbook(afterPath);

var beforeSheets = wbBefore.Worksheets.Select(ws => ws.Name).ToList();
var afterSheets = wbAfter.Worksheets.Select(ws => ws.Name).ToList();

Console.WriteLine("=== シート一覧 ===");
Console.WriteLine($"Before: {string.Join(", ", beforeSheets)}");
Console.WriteLine($"After:  {string.Join(", ", afterSheets)}");

var added = afterSheets.Except(beforeSheets).ToList();
var removed = beforeSheets.Except(afterSheets).ToList();
if (added.Count > 0) Console.WriteLine($"追加されたシート: {string.Join(", ", added)}");
if (removed.Count > 0) Console.WriteLine($"削除されたシート: {string.Join(", ", removed)}");

var common = beforeSheets.Intersect(afterSheets).ToList();
foreach (var name in common)
{
    var wsB = wbBefore.Worksheet(name);
    var wsA = wbAfter.Worksheet(name);

    var maxRow = Math.Max(wsB.LastRowUsed()?.RowNumber() ?? 0, wsA.LastRowUsed()?.RowNumber() ?? 0);
    var maxCol = Math.Max(wsB.LastColumnUsed()?.ColumnNumber() ?? 0, wsA.LastColumnUsed()?.ColumnNumber() ?? 0);

    var diffs = new List<(string Cell, string Before, string After)>();

    for (int r = 1; r <= maxRow; r++)
    {
        for (int c = 1; c <= maxCol; c++)
        {
            var vB = wsB.Cell(r, c).GetFormattedString();
            var vA = wsA.Cell(r, c).GetFormattedString();
            if (vB != vA)
            {
                var cellRef = wsB.Cell(r, c).Address.ToString();
                diffs.Add((cellRef, vB, vA));
            }
        }
    }

    if (diffs.Count > 0)
    {
        Console.WriteLine($"\n=== シート「{name}」の差分 ({diffs.Count} セル) ===");
        foreach (var (cell, before, after) in diffs.Take(100))
        {
            Console.WriteLine($"  [{cell}]");
            Console.WriteLine($"    Before: {before}");
            Console.WriteLine($"    After:  {after}");
        }
        if (diffs.Count > 100) Console.WriteLine($"  ... 他 {diffs.Count - 100} セル");
    }
}
CSEOF
```

### 3. パスに関する注意

- `dotnet run -` は一時ディレクトリで実行されるため、引数には **Windows の絶対パス** を渡すこと
- Git Bash の `/tmp/` は `C:/Users/<user>/AppData/Local/Temp/` に対応する
- パス変換が必要な場合: `cd /tmp && pwd -W` で Windows パスを確認

### 4. 結果の読み方

出力は以下の構造:
- **シート一覧**: Before/After のシート名一覧と追加・削除
- **シートごとの差分**: セルアドレス + 変更前後の値（最大100セルまで表示）

## Examples

### 出力例

```
=== シート一覧 ===
Before: 表紙, データ入力規則, 法令名選択肢, 改訂履歴
After:  表紙, データ入力規則, 法令名選択肢, 改訂履歴

=== シート「法令名選択肢」の差分 (1 セル) ===
  [B27]
    Before: マンションの建替え等の円滑化に関する法律
    After:  マンションの再生等の円滑化に関する法律

=== シート「改訂履歴」の差分 (4 セル) ===
  [A101]
    Before: 
    After:  72
  [B101]
    Before: 
    After:  4/22/2026
  [C101]
    Before: 
    After:  更新
  [D101]
    Before: 
    After:  法令名選択肢を最新化
```

### シートの追加・削除がある場合

```
=== シート一覧 ===
Before: Sheet1, Sheet2
After:  Sheet1, Sheet2, Sheet3
追加されたシート: Sheet3
```

## Guidelines

- scripting-guide に従い、C# file-based apps（パイプ実行）を使うこと
- .cs ファイルを新規作成しないこと
- ClosedXML のバージョンは `0.104.1` を指定すること
- 大量の差分がある場合はサマリを先に報告し、詳細は必要に応じて表示すること
