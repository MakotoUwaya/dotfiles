#!/usr/bin/env dotnet-script
#nullable enable
// apply-patches.cs -- Apply approved skill description patches.
//
// Reads patch files from the workspace and applies them to SKILL.md files.
// Always runs in dry-run mode unless --confirm is passed.
//
// Usage:
//     dotnet script apply-patches.cs -- --patches <dir> [--confirm] [--backup] [--output <path>]
//
// Options:
//     --patches DIR    Directory containing .patch.json files
//     --confirm        Actually write changes (default: dry-run)
//     --backup         Create .bak files before modifying (default: true)
//     --output PATH    Write changelog to this path

using System.IO;
using System.Text.Json;
using System.Text.RegularExpressions;

// --- Argument parsing ---

string? patchesDir = null;
bool confirm = false;
bool backup = true;
string output = "./changelog.md";

var cliArgs = Args.ToArray();
for (int i = 0; i < cliArgs.Length; i++)
{
    switch (cliArgs[i])
    {
        case "--patches":
            if (i + 1 < cliArgs.Length) patchesDir = cliArgs[++i];
            break;
        case "--confirm":
            confirm = true;
            break;
        case "--backup":
            backup = true;
            break;
        case "--output":
            if (i + 1 < cliArgs.Length) output = cliArgs[++i];
            break;
    }
}

if (string.IsNullOrEmpty(patchesDir))
{
    Console.Error.WriteLine("ERROR: --patches is required");
    return 1;
}

if (!Directory.Exists(patchesDir))
{
    Console.Error.WriteLine($"ERROR: Patches directory not found: {patchesDir}");
    return 1;
}

// --- Load patches ---

var patches = LoadPatches(patchesDir);
if (patches.Count == 0)
{
    Console.Error.WriteLine("No .patch.json files found.");
    return 1;
}

var mode = confirm ? "APPLY" : "DRY RUN";
Console.WriteLine();
Console.WriteLine(new string('=', 60));
Console.WriteLine($"  Skill Auditor \u2014 Patch Application ({mode})");
Console.WriteLine(new string('=', 60));
Console.WriteLine();

var changelogEntries = new List<ChangelogEntry>();

foreach (var patch in patches)
{
    var skillName = GetString(patch, "skill_name", "unknown");
    var skillPath = GetString(patch, "skill_path", "");
    var priority = GetString(patch, "priority", "?");

    Console.WriteLine($"[{priority.ToUpperInvariant()}] {skillName}");
    Console.WriteLine($"  Path: {skillPath}");
    Console.WriteLine($"  Fixes: {string.Join(", ", GetStringArray(patch, "fixes_issues"))}");

    foreach (var change in GetStringArray(patch, "changes_made"))
    {
        Console.WriteLine($"  -> {change}");
    }

    Console.WriteLine($"  Cascade risk: {GetString(patch, "cascade_risk", "?")}");

    var result = ApplyDescriptionPatch(
        skillPath: skillPath,
        currentDescription: GetString(patch, "current_description", ""),
        proposedDescription: GetString(patch, "proposed_description", ""),
        dryRun: !confirm,
        backup: backup
    );

    Console.WriteLine($"  Status: {result.Status} -- {result.Detail}");
    if (result.Preview is not null)
    {
        Console.WriteLine($"  Preview:\n{result.Preview}");
    }
    Console.WriteLine();

    changelogEntries.Add(new ChangelogEntry
    {
        Skill = skillName,
        Path = skillPath,
        Status = result.Status,
        Changes = GetStringArray(patch, "changes_made"),
        Fixes = GetStringArray(patch, "fixes_issues"),
    });
}

// --- Write changelog ---

using (var writer = new StreamWriter(output, false, System.Text.Encoding.UTF8))
{
    writer.WriteLine("# Skill Auditor Changelog");
    writer.WriteLine();
    writer.WriteLine($"**Date**: {DateTime.UtcNow:O}");
    writer.WriteLine($"**Mode**: {mode}");
    writer.WriteLine($"**Patches applied**: {changelogEntries.Count}");
    writer.WriteLine();

    foreach (var entry in changelogEntries)
    {
        writer.WriteLine($"## {entry.Skill}");
        writer.WriteLine();
        writer.WriteLine($"- **Path**: `{entry.Path}`");
        writer.WriteLine($"- **Status**: {entry.Status}");
        writer.WriteLine("- **Fixes**:");
        foreach (var fix in entry.Fixes)
        {
            writer.WriteLine($"  - {fix}");
        }
        writer.WriteLine("- **Changes**:");
        foreach (var change in entry.Changes)
        {
            writer.WriteLine($"  - {change}");
        }
        writer.WriteLine();
    }
}

Console.WriteLine($"Changelog written to: {output}");

if (!confirm)
{
    Console.WriteLine();
    Console.WriteLine("This was a dry run. To apply changes, re-run with --confirm");
}

return 0;

// =============================================================================
// Helper functions
// =============================================================================

List<JsonElement> LoadPatches(string dir)
{
    var result = new List<JsonElement>();
    var files = Directory.GetFiles(dir, "*.patch.json");
    Array.Sort(files);

    foreach (var fp in files)
    {
        try
        {
            var json = File.ReadAllText(fp);
            var doc = JsonDocument.Parse(json);
            result.Add(doc.RootElement.Clone());
        }
        catch (Exception e)
        {
            Console.Error.WriteLine($"WARNING: Could not load {fp}: {e.Message}");
        }
    }

    return result;
}

PatchResult ApplyDescriptionPatch(
    string skillPath,
    string currentDescription,
    string proposedDescription,
    bool dryRun,
    bool backup)
{
    if (!File.Exists(skillPath))
    {
        return new PatchResult { Status = "error", Detail = $"File not found: {skillPath}" };
    }

    string content;
    try
    {
        content = File.ReadAllText(skillPath);
    }
    catch (Exception e)
    {
        return new PatchResult { Status = "error", Detail = $"Could not read: {e.Message}" };
    }

    var frontmatterMatch = Regex.Match(content, @"^(---\s*\n)(.*?)(\n---\s*\n)", RegexOptions.Singleline);
    if (!frontmatterMatch.Success)
    {
        return new PatchResult { Status = "error", Detail = "No YAML frontmatter found in SKILL.md" };
    }

    var fmContent = frontmatterMatch.Groups[2].Value;
    var fmStart = frontmatterMatch.Groups[2].Index;

    string[] descPatterns =
    [
        @"(description\s*:\s*[>|]-?\s*\n)((?:\s+.*\n)*)",
        @"(description\s*:\s*)(.*)",
    ];

    foreach (var pattern in descPatterns)
    {
        var match = Regex.Match(fmContent, pattern);
        if (match.Success)
        {
            var indent = "  ";
            var wrappedLines = WrapText(proposedDescription, width: 76, indent: indent);
            var newDescBlock = $"description: >\n{wrappedLines}\n";

            var newContent = string.Concat(
                content.AsSpan(0, fmStart + match.Index),
                newDescBlock,
                content.AsSpan(fmStart + match.Index + match.Length)
            );

            if (dryRun)
            {
                return new PatchResult
                {
                    Status = "dry_run",
                    Detail = "Would apply change",
                    Preview = newDescBlock.Trim(),
                };
            }

            if (backup)
            {
                File.Copy(skillPath, skillPath + ".bak", overwrite: true);
            }

            File.WriteAllText(skillPath, newContent);
            return new PatchResult { Status = "applied", Detail = "Description updated" };
        }
    }

    return new PatchResult { Status = "error", Detail = "Could not locate description field in frontmatter" };
}

string WrapText(string text, int width = 76, string indent = "  ")
{
    var words = text.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries);
    var lines = new List<string>();
    var currentLine = indent;

    foreach (var word in words)
    {
        if (currentLine.Length + word.Length + 1 > width)
        {
            lines.Add(currentLine);
            currentLine = indent + word;
        }
        else
        {
            if (currentLine == indent)
            {
                currentLine += word;
            }
            else
            {
                currentLine += " " + word;
            }
        }
    }

    if (currentLine.Trim().Length > 0)
    {
        lines.Add(currentLine);
    }

    return string.Join("\n", lines);
}

string GetString(JsonElement el, string prop, string defaultValue = "")
{
    if (el.TryGetProperty(prop, out var val) && val.ValueKind == JsonValueKind.String)
    {
        return val.GetString() ?? defaultValue;
    }
    return defaultValue;
}

string[] GetStringArray(JsonElement el, string prop)
{
    if (el.TryGetProperty(prop, out var val) && val.ValueKind == JsonValueKind.Array)
    {
        var items = new List<string>();
        foreach (var item in val.EnumerateArray())
        {
            if (item.ValueKind == JsonValueKind.String)
            {
                items.Add(item.GetString() ?? "");
            }
        }
        return items.ToArray();
    }
    return [];
}

// =============================================================================
// Data types
// =============================================================================

record PatchResult
{
    public string Status { get; init; } = "";
    public string Detail { get; init; } = "";
    public string? Preview { get; init; }
}

record ChangelogEntry
{
    public string Skill { get; init; } = "";
    public string Path { get; init; } = "";
    public string Status { get; init; } = "";
    public string[] Changes { get; init; } = [];
    public string[] Fixes { get; init; } = [];
}
