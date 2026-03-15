---
name: scripting-guide
description: ワンライナーや小規模スクリプトでのデータ処理方法を解説するガイド。Python・Ruby・bash スクリプト等でデータ処理や計算・ファイル生成を行おうとする場合には、必ずこのスキルを参照し、C# file-based apps で実行すること。
---

# データ処理スクリプト作成ガイド（C# file-based apps）

このスキルは、C# file-based apps を使ってファイルを作らずにデータ処理を行う方法を提供します。

**適用バージョン:** .NET 10 SDK 以降（C# 14 以降）

## 基本方針

スクリプト実行前に `dotnet --version` で .NET 10 以降がインストールされていることを確認してください。

コードは **必ずパイプで `dotnet run -` に渡して実行** してください。
`Set-Content` や `Out-File` 等で `.cs` ファイルを新規作成してから実行する方法は **禁止** です。

**優先順位:**
1. **パイプ実行（必須）:** コード文字列を `dotnet run -` に直接パイプして実行する
2. **既存ファイル実行:** プロジェクトに既に存在する `.cs` ファイルを `dotnet <file>.cs` で実行する

`#:package` ディレクティブが必要な場合も、パイプ実行で対応できます（後述の「外部ライブラリを使う場合」を参照）。

## ワンライナー実行（最優先）

### 基本

**PowerShell:**
```powershell
'Console.WriteLine("Hello!");' | dotnet run -
```

**Bash:**
```bash
echo 'Console.WriteLine("Hello!");' | dotnet run -
```

### 複数行

**PowerShell:**
```powershell
@'
var sum = Enumerable.Range(1, 100).Sum();
Console.WriteLine($"合計: {sum}");
'@ | dotnet run -
```

**Bash:**
```bash
dotnet run - << 'EOF'
var sum = Enumerable.Range(1, 100).Sum();
Console.WriteLine($"合計: {sum}");
EOF
```

### 暗黙的に使えるnamespace

以下は `using` 不要で使えます:

- `System`, `System.IO`, `System.Collections.Generic`, `System.Linq`, `System.Net.Http`, `System.Threading`, `System.Threading.Tasks`

## 標準ライブラリでの処理

### JSON処理（パッケージ不要）

`json.cs`:
```csharp
using System.Text.Json;

var json = Console.In.ReadToEnd();
var doc = JsonDocument.Parse(json);
Console.WriteLine(doc.RootElement.GetProperty("name"));
```

実行:
```powershell
'{"name":"太郎"}' | dotnet json.cs
```

### Native AOT に関する注意

file-based apps はデフォルトで **Native AOT** が有効です。
`JsonSerializer.Serialize<T>()` / `Deserialize<T>()` はリフレクション依存のため、**実行時に失敗** します。

**安全パターン:**
- **`JsonDocument`（DOM アクセス）を推奨**（上記の例を参照）
- POCO へのデシリアライズが必要な場合は `JsonSerializerContext` ソース生成版を使う

```csharp
using System.Text.Json;
using System.Text.Json.Serialization;

var json = """{"name":"太郎","age":30}""";
var person = JsonSerializer.Deserialize(json, AppJsonContext.Default.Person)!;
Console.WriteLine($"{person.Name} ({person.Age})");

record Person(string Name, int Age);

[JsonSerializable(typeof(Person))]
partial class AppJsonContext : JsonSerializerContext { }
```

## 外部ライブラリを使う場合

`#:package` ディレクティブが必要な場合も、パイプで実行します。ファイルを作成しないでください。

**バージョン指定は必須です。** 再現性を確保するため `#:package <名前>@<バージョン>` の形式で記述してください。

```
# NG: バージョンなし（ビルドごとに異なるバージョンが解決される可能性あり）
#:package CsvHelper

# OK: バージョン固定
#:package CsvHelper@33.0.1
```

### CSV処理

```powershell
@'
#:package CsvHelper@33.0.1

using CsvHelper;
using System.Globalization;

using var reader = new StreamReader(args[0]);
using var csv = new CsvReader(reader, CultureInfo.InvariantCulture);

var count = csv.GetRecords<dynamic>().Count();
Console.WriteLine($"レコード数: {count}");
'@ | dotnet run - -- data.csv
```

### Excel処理

```powershell
@'
#:package ClosedXML@0.104.1

using ClosedXML.Excel;

using var workbook = new XLWorkbook(args[0]);
var worksheet = workbook.Worksheet(1);

foreach (var row in worksheet.RowsUsed())
{
    Console.WriteLine(row.Cell(1).Value);
}
'@ | dotnet run - -- Employee.xlsx
```

## よく使うライブラリ

| 用途 | ディレクティブ | 備考 |
|------|---------------|------|
| JSON処理 | （不要） | `System.Text.Json` が標準で利用可能 |
| CSV処理 | `#:package CsvHelper@33.0.1` | |
| Excel処理 | `#:package ClosedXML@0.104.1` | |

## ファイル出力の注意点

`dotnet run -`（パイプ実行）は一時ディレクトリで実行される。
コード内で `StreamWriter` や `File.WriteAllText` を使うと、**CWD ではなく一時ディレクトリにファイルが作られる**。

### NG: コード内でファイル書き込み

```bash
# data.txt は一時ディレクトリに作られ、CWD には残らない
dotnet run - << 'EOF'
using var writer = new StreamWriter("data.txt");
writer.WriteLine("hello");
EOF
```

### OK: stdout に出力してシェルでリダイレクト

```bash
# CWD の data.txt に正しく書き込まれる
dotnet run - << 'EOF' > data.txt
Console.WriteLine("hello");
EOF
```

**原則: ファイル出力は `Console.WriteLine` + シェルリダイレクト (`>`) を使う。**

## 実用パターン

### 標準入力とファイル引数の両対応

```csharp
var input = args.Length > 0
    ? File.ReadAllText(args[0])
    : Console.In.ReadToEnd();

Console.WriteLine(input.ToUpper());
```

使い方:
```powershell
# ファイルから
dotnet script.cs -- input.txt

# 標準入力から
Get-Content input.txt | dotnet script.cs
```

### エラーハンドリング

```csharp
try
{
    // 処理
}
catch (Exception ex)
{
    Console.Error.WriteLine($"エラー: {ex.Message}");
    return 1;
}
```

## トラブルシューティング

### .csproj との競合

既存の `.csproj` があるディレクトリ内で `dotnet run <file>.cs` を実行すると、プロジェクトとの競合が発生します。
パイプ実行（`... | dotnet run -`）は一時ディレクトリで動くため、この問題は発生しません。

### 継承設定ファイルに注意

`global.json`、`Directory.Build.props`、`Directory.Build.targets` などが親ディレクトリに存在すると、file-based apps にも継承されます。
予期しないビルドエラーが出た場合は、これらのファイルの影響を確認してください。

### キャッシュクリア

file-based apps のビルドキャッシュをクリアするには:

```bash
dotnet clean <file>.cs
```

## 参考資料

- [File-based apps](https://learn.microsoft.com/dotnet/core/sdk/file-based-apps)
- [Top-level statements](https://learn.microsoft.com/dotnet/csharp/fundamentals/program-structure/top-level-statements)
