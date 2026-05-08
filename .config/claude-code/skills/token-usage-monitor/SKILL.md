---
name: token-usage-monitor
description: Claude Code のセッションログ (~/.claude/projects/**/*.jsonl) を集計してトークン消費量を観測する。ECC 導入前後の Before/After 比較、週次モニタリング、cache hit 率の確認に使う。「トークン集計」「token usage」「使用量集計」「Claude Code 消費量」で起動。
---

# token-usage-monitor

Claude Code がローカルに保存しているセッションログを集計し、トークン消費量・cache hit 率・model 別内訳を出力する。

## 用途

- **ECC など大型プラグイン導入前後の Before/After 比較**
- 週次のトークン消費モニタリング
- cache 戦略の効果確認（cache_read が支配的になっているか）
- 仕事 PC / プライベート PC それぞれで個別にベースライン取得

## セッションログの場所

`~/.claude/projects/<encoded-project-path>/<session-uuid>.jsonl`
および `~/.claude/projects/<encoded-project-path>/<session-uuid>/subagents/agent-<id>.jsonl`

各行は JSONL。`type=assistant` の行が `message.usage` を持つ。

## 実行方法（C# file-based apps）

`scripting-guide` のルールに従い、コードはパイプで `dotnet run -` に渡す。
**.NET 10 SDK 以降** が必須。

### Bash / WSL2

```bash
dotnet run - -- "$HOME/.claude/projects" --days 7 << 'EOF'
using System.Text.Json;
using System.Globalization;

string projectsDir = args[0];
int days = 7;
for (int i = 1; i < args.Length - 1; i++)
{
    if (args[i] == "--days") days = int.Parse(args[i + 1]);
}

var since = DateTime.UtcNow.AddDays(-days);
var byModel = new Dictionary<string, (long input, long output, long cacheRead, long cacheCreate, int turns)>();
long totalInput = 0, totalOutput = 0, totalCacheRead = 0, totalCacheCreate = 0;
int totalTurns = 0;
var sessionIds = new HashSet<string>();
var projectCounts = new Dictionary<string, int>();

foreach (var file in Directory.EnumerateFiles(projectsDir, "*.jsonl", SearchOption.AllDirectories))
{
    var fi = new FileInfo(file);
    if (fi.LastWriteTimeUtc < since) continue;

    string projectName = Path.GetRelativePath(projectsDir, file).Split(Path.DirectorySeparatorChar)[0];

    foreach (var line in File.ReadLines(file))
    {
        if (string.IsNullOrWhiteSpace(line)) continue;
        JsonDocument? doc = null;
        try { doc = JsonDocument.Parse(line); } catch { continue; }
        using (doc)
        {
            var root = doc.RootElement;
            if (!root.TryGetProperty("timestamp", out var ts)) continue;
            if (!DateTime.TryParse(ts.GetString(), null, DateTimeStyles.RoundtripKind, out var t)) continue;
            if (t.ToUniversalTime() < since) continue;

            if (root.TryGetProperty("sessionId", out var sid) && sid.ValueKind == JsonValueKind.String)
                sessionIds.Add(sid.GetString()!);

            if (!root.TryGetProperty("message", out var msg) || msg.ValueKind != JsonValueKind.Object) continue;
            if (!msg.TryGetProperty("usage", out var usage) || usage.ValueKind != JsonValueKind.Object) continue;

            string model = msg.TryGetProperty("model", out var m) && m.ValueKind == JsonValueKind.String ? m.GetString()! : "unknown";
            long input = usage.TryGetProperty("input_tokens", out var i) && i.ValueKind == JsonValueKind.Number ? i.GetInt64() : 0;
            long output = usage.TryGetProperty("output_tokens", out var o) && o.ValueKind == JsonValueKind.Number ? o.GetInt64() : 0;
            long cacheRead = usage.TryGetProperty("cache_read_input_tokens", out var cr) && cr.ValueKind == JsonValueKind.Number ? cr.GetInt64() : 0;
            long cacheCreate = usage.TryGetProperty("cache_creation_input_tokens", out var cc) && cc.ValueKind == JsonValueKind.Number ? cc.GetInt64() : 0;

            totalInput += input; totalOutput += output; totalCacheRead += cacheRead; totalCacheCreate += cacheCreate; totalTurns++;
            if (!byModel.TryGetValue(model, out var prev)) prev = (0, 0, 0, 0, 0);
            byModel[model] = (prev.input + input, prev.output + output, prev.cacheRead + cacheRead, prev.cacheCreate + cacheCreate, prev.turns + 1);
            projectCounts[projectName] = projectCounts.GetValueOrDefault(projectName) + 1;
        }
    }
}

double cacheHitRate = (totalInput + totalCacheRead) > 0 ? (double)totalCacheRead / (totalInput + totalCacheRead) : 0;
Console.WriteLine($"=== Token usage (last {days} days, since {since:yyyy-MM-dd UTC}) ===");
Console.WriteLine($"Sessions:        {sessionIds.Count}");
Console.WriteLine($"Assistant turns: {totalTurns}");
Console.WriteLine($"Input tokens:    {totalInput,15:N0}");
Console.WriteLine($"Output tokens:   {totalOutput,15:N0}");
Console.WriteLine($"Cache read:      {totalCacheRead,15:N0}");
Console.WriteLine($"Cache create:    {totalCacheCreate,15:N0}");
Console.WriteLine($"Cache hit rate:  {cacheHitRate:P1}");
if (totalTurns > 0)
    Console.WriteLine($"Avg per turn:    input={(double)totalInput / totalTurns:N0}, output={(double)totalOutput / totalTurns:N0}, cache_read={(double)totalCacheRead / totalTurns:N0}");

Console.WriteLine();
Console.WriteLine("=== By model ===");
foreach (var kv in byModel.OrderByDescending(x => x.Value.input + x.Value.output))
    Console.WriteLine($"  {kv.Key,-30} turns={kv.Value.turns,5}  in={kv.Value.input,12:N0}  out={kv.Value.output,10:N0}  cache_read={kv.Value.cacheRead,12:N0}");

Console.WriteLine();
Console.WriteLine("=== Top 5 projects by turn count ===");
foreach (var kv in projectCounts.OrderByDescending(x => x.Value).Take(5))
    Console.WriteLine($"  {kv.Value,5}  {kv.Key}");
EOF
```

### PowerShell

```powershell
@'
using System.Text.Json;
using System.Globalization;

string projectsDir = args[0];
int days = 7;
for (int i = 1; i < args.Length - 1; i++)
{
    if (args[i] == "--days") days = int.Parse(args[i + 1]);
}

var since = DateTime.UtcNow.AddDays(-days);
var byModel = new Dictionary<string, (long input, long output, long cacheRead, long cacheCreate, int turns)>();
long totalInput = 0, totalOutput = 0, totalCacheRead = 0, totalCacheCreate = 0;
int totalTurns = 0;
var sessionIds = new HashSet<string>();
var projectCounts = new Dictionary<string, int>();

foreach (var file in Directory.EnumerateFiles(projectsDir, "*.jsonl", SearchOption.AllDirectories))
{
    var fi = new FileInfo(file);
    if (fi.LastWriteTimeUtc < since) continue;
    string projectName = Path.GetRelativePath(projectsDir, file).Split(Path.DirectorySeparatorChar)[0];

    foreach (var line in File.ReadLines(file))
    {
        if (string.IsNullOrWhiteSpace(line)) continue;
        JsonDocument? doc = null;
        try { doc = JsonDocument.Parse(line); } catch { continue; }
        using (doc)
        {
            var root = doc.RootElement;
            if (!root.TryGetProperty("timestamp", out var ts)) continue;
            if (!DateTime.TryParse(ts.GetString(), null, DateTimeStyles.RoundtripKind, out var t)) continue;
            if (t.ToUniversalTime() < since) continue;
            if (root.TryGetProperty("sessionId", out var sid) && sid.ValueKind == JsonValueKind.String) sessionIds.Add(sid.GetString()!);
            if (!root.TryGetProperty("message", out var msg) || msg.ValueKind != JsonValueKind.Object) continue;
            if (!msg.TryGetProperty("usage", out var usage) || usage.ValueKind != JsonValueKind.Object) continue;

            string model = msg.TryGetProperty("model", out var m) && m.ValueKind == JsonValueKind.String ? m.GetString()! : "unknown";
            long input = usage.TryGetProperty("input_tokens", out var i) && i.ValueKind == JsonValueKind.Number ? i.GetInt64() : 0;
            long output = usage.TryGetProperty("output_tokens", out var o) && o.ValueKind == JsonValueKind.Number ? o.GetInt64() : 0;
            long cacheRead = usage.TryGetProperty("cache_read_input_tokens", out var cr) && cr.ValueKind == JsonValueKind.Number ? cr.GetInt64() : 0;
            long cacheCreate = usage.TryGetProperty("cache_creation_input_tokens", out var cc) && cc.ValueKind == JsonValueKind.Number ? cc.GetInt64() : 0;

            totalInput += input; totalOutput += output; totalCacheRead += cacheRead; totalCacheCreate += cacheCreate; totalTurns++;
            if (!byModel.TryGetValue(model, out var prev)) prev = (0, 0, 0, 0, 0);
            byModel[model] = (prev.input + input, prev.output + output, prev.cacheRead + cacheRead, prev.cacheCreate + cacheCreate, prev.turns + 1);
            projectCounts[projectName] = projectCounts.GetValueOrDefault(projectName) + 1;
        }
    }
}

double cacheHitRate = (totalInput + totalCacheRead) > 0 ? (double)totalCacheRead / (totalInput + totalCacheRead) : 0;
Console.WriteLine($"=== Token usage (last {days} days, since {since:yyyy-MM-dd UTC}) ===");
Console.WriteLine($"Sessions:        {sessionIds.Count}");
Console.WriteLine($"Assistant turns: {totalTurns}");
Console.WriteLine($"Input tokens:    {totalInput,15:N0}");
Console.WriteLine($"Output tokens:   {totalOutput,15:N0}");
Console.WriteLine($"Cache read:      {totalCacheRead,15:N0}");
Console.WriteLine($"Cache create:    {totalCacheCreate,15:N0}");
Console.WriteLine($"Cache hit rate:  {cacheHitRate:P1}");
if (totalTurns > 0)
    Console.WriteLine($"Avg per turn:    input={(double)totalInput / totalTurns:N0}, output={(double)totalOutput / totalTurns:N0}, cache_read={(double)totalCacheRead / totalTurns:N0}");

Console.WriteLine();
Console.WriteLine("=== By model ===");
foreach (var kv in byModel.OrderByDescending(x => x.Value.input + x.Value.output))
    Console.WriteLine($"  {kv.Key,-30} turns={kv.Value.turns,5}  in={kv.Value.input,12:N0}  out={kv.Value.output,10:N0}  cache_read={kv.Value.cacheRead,12:N0}");

Console.WriteLine();
Console.WriteLine("=== Top 5 projects by turn count ===");
foreach (var kv in projectCounts.OrderByDescending(x => x.Value).Take(5))
    Console.WriteLine($"  {kv.Value,5}  {kv.Key}");
'@ | dotnet run - -- "$HOME\.claude\projects" --days 7
```

## オプション

- `--days N`: 集計対象の過去日数（デフォルト 7）

## 出力例

```
=== Token usage (last 7 days, since 2026-05-01 UTC) ===
Sessions:        12
Assistant turns: 348
Input tokens:        1,234,567
Output tokens:         234,567
Cache read:          8,901,234
Cache create:          456,789
Cache hit rate:  87.8%
Avg per turn:    input=3,547, output=674, cache_read=25,578

=== By model ===
  claude-opus-4-7                turns=  280  in= 1,000,000  out=  200,000  cache_read=  7,500,000
  claude-haiku-4-5-20251001      turns=   68  in=   234,567  out=   34,567  cache_read=  1,401,234

=== Top 5 projects by turn count ===
    180  C--Users-makot-ghq-github-com-MakotoUwaya-dotfiles
     45  C--Users-makot-ghq-github-com-MakotoUwaya-nijiviewer
     ...
```

## ベースライン記録の運用

ECC 導入前後の比較は以下の手順で行う：

1. **導入前**: このスキルで `--days 7` を実行 → 結果を `~/.claude/projects/<dotfiles>/memory/project_ecc_token_baseline.md` に貼り付け
2. **導入直後**: 新規セッションで `/context` を実行 → 同 memory に「常駐コスト」として追記
3. **1 週間後**: 再度集計 → `project_ecc_token_after_1week.md` に保存し Before/After を比較
4. 判断基準（プロジェクト memory `project_ecc_adoption.md` 参照）:
   - 平均 input が **+30% 以下**: 継続
   - **+30〜+60%**: `ECC_HOOK_PROFILE` を `minimal` に戻す等
   - **+60% 超**: 部分採用に切り戻し

## 注意

- スクリプトはセッションログを **読むだけ** で破壊的操作なし
- 内容は集計値のみ memory 保存し、対話本文は memory に書かない
- 仕事 PC とプライベート PC で **別々にベースライン取得**（タスク性質が違うため）
