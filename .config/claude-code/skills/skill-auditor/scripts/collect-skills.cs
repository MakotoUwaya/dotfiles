#!/usr/bin/env dotnet-script
#nullable enable
#r "nuget: SharpToken, 2.0.3"

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;

// ============================================================
// Entry point (top-level statements must precede type declarations)
// ============================================================

// Parse CLI arguments
var cliArgs = CliArgs.Parse(Args.ToArray());

var result = SkillCollector.Collect(
    cliArgs.SkillDirs,
    cliArgs.Verbose,
    includeProjectSkills: !cliArgs.NoProjectSkills);

// Write output
var outputPath = Path.GetFullPath(cliArgs.Output);
var outputDir = Path.GetDirectoryName(outputPath);
if (outputDir != null && !Directory.Exists(outputDir))
    Directory.CreateDirectory(outputDir);

using (var stream = File.Create(outputPath))
using (var writer = new Utf8JsonWriter(stream, new JsonWriterOptions { Indented = true }))
{
    JsonOutput.WriteManifest(writer, result);
}

// Print summary to stdout
var summary = (Dictionary<string, object>)result["summary"]!;
var budget = (Dictionary<string, object>)result["attention_budget"]!;
var byScope = (Dictionary<string, int>)summary["by_scope"];
int globalCount = byScope.GetValueOrDefault("global");
int projectLocalCount = byScope.GetValueOrDefault("project-local");

Console.WriteLine($"Found {summary["total_skills"]} skills ({globalCount} global, {projectLocalCount} project-local)");
Console.WriteLine($"  Attention budget: {budget["total_description_tokens"]} tokens total " +
    $"({budget["global_description_tokens"]} global), " +
    $"median {budget["median_tokens_per_skill"]} per skill");

var perProject = (Dictionary<string, object>)budget["per_project"];
foreach (var (pp, pbObj) in perProject)
{
    var pb = (Dictionary<string, object>)pbObj;
    var localNames = (List<string>)pb["local_skill_names"];
    Console.WriteLine($"  Project {Path.GetFileName(pp)}: " +
        $"{pb["total_tokens"]} tokens ({pb["local_tokens"]} local + " +
        $"{pb["global_tokens"]} global), " +
        $"skills: {string.Join(", ", localNames)}");
}

var above2x = (List<string>)budget["skills_above_2x_median"];
if (above2x.Count > 0)
    Console.WriteLine($"  Oversized descriptions (>2x median): {string.Join(", ", above2x)}");

var noDesc = (List<string>)summary["skills_without_description"];
if (noDesc.Count > 0)
    Console.WriteLine($"  Warning: {noDesc.Count} skills have no description");

var descOverlaps = (List<Dictionary<string, object>>)result["description_overlaps"]!;
if (descOverlaps.Count > 0)
{
    var top = descOverlaps[0];
    Console.WriteLine($"  Highest keyword overlap: {top["skill_a"]} <-> {top["skill_b"]} " +
        $"({top["shared_count"]} shared words)");
}

Console.WriteLine($"Output: {cliArgs.Output}");

// ============================================================
// Type declarations
// ============================================================

/// <summary>Token counting: SharpToken preferred, character-based fallback.</summary>
class TokenCounter
{
    private static SharpToken.GptEncoding? _enc;
    private static bool _initialized;

    private static void EnsureInitialized()
    {
        if (_initialized) return;
        _initialized = true;
        try
        {
            _enc = SharpToken.GptEncoding.GetEncoding("cl100k_base");
        }
        catch
        {
            _enc = null;
        }
    }

    public static int CountTokens(string text)
    {
        EnsureInitialized();
        if (_enc != null)
        {
            try { return _enc.Encode(text).Count; }
            catch { /* fallback */ }
        }
        return Math.Max(1, text.Length / 4);
    }
}

/// <summary>Standard skill locations in Claude Code.</summary>
class Defaults
{
    public static readonly string[] SkillDirs =
    {
        "/mnt/skills/public",
        "/mnt/skills/private",
        "/mnt/skills/examples",
        "/mnt/skills/user",
        Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".claude", "skills"),
        ".claude/skills",
    };
}

/// <summary>CLI argument container.</summary>
class CliArgs
{
    public List<string>? SkillDirs;
    public string Output = "./skill-manifest.json";
    public bool Verbose;
    public bool NoProjectSkills;

    public static CliArgs Parse(string[] args)
    {
        var result = new CliArgs();
        for (int i = 0; i < args.Length; i++)
        {
            switch (args[i])
            {
                case "--skill-dirs":
                    result.SkillDirs = new List<string>();
                    while (i + 1 < args.Length && !args[i + 1].StartsWith("--"))
                    {
                        result.SkillDirs.Add(args[++i]);
                    }
                    break;
                case "--output":
                    if (i + 1 < args.Length) result.Output = args[++i];
                    break;
                case "--verbose":
                    result.Verbose = true;
                    break;
                case "--no-project-skills":
                    result.NoProjectSkills = true;
                    break;
            }
        }
        return result;
    }
}

/// <summary>Simple YAML-like parser for frontmatter.</summary>
class YamlParser
{
    public static Dictionary<string, string> Parse(string text)
    {
        var result = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        string? currentKey = null;
        var currentValueLines = new List<string>();
        bool isMultiline = false;

        foreach (var line in text.Split('\n'))
        {
            var keyMatch = Regex.Match(line, @"^(\w[\w-]*)\s*:\s*(.*)");
            if (keyMatch.Success && !(isMultiline && line.StartsWith(" ")))
            {
                if (currentKey != null)
                    result[currentKey] = FinalizeValue(currentValueLines, isMultiline);

                currentKey = keyMatch.Groups[1].Value.ToLowerInvariant();
                var value = keyMatch.Groups[2].Value.Trim();

                if (value is ">" or "|" or ">-" or "|-")
                {
                    isMultiline = true;
                    currentValueLines = new List<string>();
                }
                else
                {
                    isMultiline = false;
                    currentValueLines = new List<string> { value.Trim('\'', '"') };
                }
            }
            else if (currentKey != null && isMultiline)
            {
                currentValueLines.Add(line.Trim());
            }
        }

        if (currentKey != null)
            result[currentKey] = FinalizeValue(currentValueLines, isMultiline);

        return result;
    }

    private static string FinalizeValue(List<string> lines, bool isMultiline)
    {
        if (isMultiline)
            return string.Join(" ", lines.Where(l => !string.IsNullOrEmpty(l))).Trim();
        return lines.Count > 0 ? lines[0] : "";
    }
}

/// <summary>Skill metadata model.</summary>
class SkillInfo
{
    public string Filepath { get; set; } = "";
    public string? FilepathResolved { get; set; }
    public string? Name { get; set; }
    public string? Description { get; set; }
    public string? DescriptionRaw { get; set; }
    public string? Trigger { get; set; }
    public string? BodyPreview { get; set; }
    public int FullContentLength { get; set; }
    public int DescriptionTokens { get; set; }
    public bool DisableModelInvocation { get; set; }
    public string Category { get; set; } = "other";
    public string Scope { get; set; } = "global";
    public string? ProjectPath { get; set; }
    public string? Error { get; set; }
}

/// <summary>Main collection logic.</summary>
class SkillCollector
{
    private static readonly Regex FrontmatterRegex =
        new(@"^---\s*\n(.*?)\n---\s*\n", RegexOptions.Singleline);

    public static SkillInfo? ParseSkillMd(string filepath)
    {
        string content;
        try
        {
            content = File.ReadAllText(filepath, Encoding.UTF8);
        }
        catch (Exception e)
        {
            return new SkillInfo { Error = e.Message, Filepath = filepath };
        }

        string resolved;
        try
        {
            var linkTarget = File.ResolveLinkTarget(filepath, returnFinalTarget: true);
            resolved = linkTarget?.FullName ?? Path.GetFullPath(filepath);
        }
        catch
        {
            resolved = Path.GetFullPath(filepath);
        }

        var result = new SkillInfo
        {
            Filepath = filepath,
            FilepathResolved = resolved != filepath ? resolved : null,
            FullContentLength = content.Length,
        };

        // Parse YAML frontmatter
        string body;
        var fmMatch = FrontmatterRegex.Match(content);
        if (fmMatch.Success)
        {
            var fm = YamlParser.Parse(fmMatch.Groups[1].Value);
            if (fm.TryGetValue("name", out var n)) result.Name = n;
            if (fm.TryGetValue("description", out var d)) result.Description = d;
            if (fm.TryGetValue("trigger", out var t)) result.Trigger = t;
            if (fm.TryGetValue("disable-model-invocation", out var dmi))
                result.DisableModelInvocation = dmi.ToLowerInvariant() is "true" or "yes" or "1";
            body = content[fmMatch.Length..];
        }
        else
        {
            body = content;
        }

        if (string.IsNullOrEmpty(result.Name))
            result.Name = Path.GetFileName(Path.GetDirectoryName(filepath)) ?? "unknown";

        // Body preview: first ~500 chars up to 2nd heading
        body = body.Trim();
        if (!string.IsNullOrEmpty(body))
        {
            var lines = body.Split('\n');
            var previewLines = new List<string>();
            int headingCount = 0;
            int charSum = 0;
            foreach (var line in lines)
            {
                if (line.StartsWith('#') && previewLines.Count > 0)
                {
                    headingCount++;
                    if (headingCount >= 2) break;
                }
                previewLines.Add(line);
                charSum += line.Length;
                if (charSum > 500) break;
            }
            result.BodyPreview = string.Join("\n", previewLines).Trim();
        }

        result.DescriptionRaw = result.Description ?? "";

        // Token counting for attention budget analysis
        var desc = result.Description ?? "";
        result.DescriptionTokens = !string.IsNullOrEmpty(desc) ? TokenCounter.CountTokens(desc) : 0;

        return result;
    }

    public static List<(string Dir, string ProjectRoot)> DiscoverProjectSkillDirs(bool verbose)
    {
        var claudeProjects = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
            ".claude", "projects");

        if (!Directory.Exists(claudeProjects))
            return new List<(string, string)>();

        var results = new List<(string, string)>();

        foreach (var dirPath in Directory.EnumerateDirectories(claudeProjects))
        {
            var name = Path.GetFileName(dirPath);
            if (name == null) continue;
            if (!Directory.Exists(dirPath)) continue;

            var decoded = name.TrimStart('-');
            var parts = decoded.Split('-');

            // Try simple slash-join first
            var candidate = "/" + string.Join("/", parts);
            var skillDir = Path.Combine(candidate, ".claude", "skills");
            if (Directory.Exists(skillDir))
            {
                if (verbose)
                    Console.Error.WriteLine($"  Project-local skills: {skillDir}");
                results.Add((skillDir, candidate));
                continue;
            }

            // Try reconstructing dots (github-com -> github.com, etc.)
            bool found = false;
            for (int i = 0; i < parts.Length - 1 && !found; i++)
            {
                var dotted = new List<string>();
                for (int k = 0; k < parts.Length; k++)
                {
                    if (k == i)
                        dotted.Add(parts[k] + "." + parts[k + 1]);
                    else if (k == i + 1)
                        continue;
                    else
                        dotted.Add(parts[k]);
                }
                candidate = "/" + string.Join("/", dotted);
                skillDir = Path.Combine(candidate, ".claude", "skills");
                if (Directory.Exists(skillDir))
                {
                    if (verbose)
                        Console.Error.WriteLine($"  Project-local skills: {skillDir}");
                    results.Add((skillDir, candidate));
                    found = true;
                }
            }
        }

        return results;
    }

    public static List<SkillInfo> FindSkills(
        List<string> skillDirs,
        List<(string Dir, string ProjectRoot)>? projectSkillDirs,
        bool verbose)
    {
        var skills = new List<SkillInfo>();
        var seenPaths = new HashSet<string>();

        void Scan(string baseDir, string scope, string? projectPath)
        {
            if (baseDir.StartsWith("~"))
                baseDir = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
                    baseDir[2..]);

            if (!Directory.Exists(baseDir))
            {
                if (verbose)
                    Console.Error.WriteLine($"  Skipping (not found): {baseDir}");
                return;
            }

            IEnumerable<string> files;
            try
            {
                files = Directory.EnumerateFiles(baseDir, "SKILL.md", SearchOption.AllDirectories);
            }
            catch
            {
                return;
            }

            foreach (var fp in files)
            {
                string realFp;
                try
                {
                    var linkTarget = File.ResolveLinkTarget(fp, returnFinalTarget: true);
                    realFp = linkTarget?.FullName ?? Path.GetFullPath(fp);
                }
                catch
                {
                    realFp = Path.GetFullPath(fp);
                }

                if (!seenPaths.Add(realFp)) continue;

                if (verbose)
                    Console.Error.WriteLine($"  Found: {fp}");

                var parsed = ParseSkillMd(fp);
                if (parsed == null) continue;

                if (fp.Contains("/public/"))
                    parsed.Category = "public";
                else if (fp.Contains("/private/"))
                    parsed.Category = "private";
                else if (fp.Contains("/examples/"))
                    parsed.Category = "example";
                else if (fp.Contains("/user/") || fp.Contains("/.claude/skills/"))
                    parsed.Category = "user";
                else
                    parsed.Category = "other";

                parsed.Scope = scope;
                parsed.ProjectPath = projectPath;
                skills.Add(parsed);
            }
        }

        foreach (var dir in skillDirs)
            Scan(dir, "global", null);

        if (projectSkillDirs != null)
        {
            foreach (var (dir, projectRoot) in projectSkillDirs)
                Scan(dir, "project-local", projectRoot);
        }

        return skills;
    }

    public static Dictionary<string, object?> Collect(
        List<string>? skillDirs, bool verbose, bool includeProjectSkills)
    {
        var globalDirs = new List<string>(skillDirs ?? (IEnumerable<string>)Defaults.SkillDirs);

        var projectSkillDirs = new List<(string, string)>();
        if (includeProjectSkills)
            projectSkillDirs = DiscoverProjectSkillDirs(verbose);

        var skills = FindSkills(globalDirs, projectSkillDirs, verbose);

        skills.Sort((a, b) =>
        {
            int c = string.Compare(a.Scope, b.Scope, StringComparison.Ordinal);
            if (c != 0) return c;
            c = string.Compare(a.Category, b.Category, StringComparison.Ordinal);
            if (c != 0) return c;
            return string.Compare(a.Name, b.Name, StringComparison.Ordinal);
        });

        // Description overlap analysis
        var descriptions = new Dictionary<string, string>();
        foreach (var s in skills)
        {
            var desc = s.Description ?? "";
            if (!string.IsNullOrEmpty(desc) && s.Name != null)
                descriptions[s.Name] = desc.ToLowerInvariant();
        }

        var stopWords = new HashSet<string>
        {
            "a","an","the","is","are","for","to","of","in",
            "and","or","this","that","with","use","when","it",
            "not","do","be","as","on","at","by","if","any"
        };

        var overlaps = new List<Dictionary<string, object>>();
        var skillNames = descriptions.Keys.ToList();
        for (int i = 0; i < skillNames.Count; i++)
        {
            for (int j = i + 1; j < skillNames.Count; j++)
            {
                var a = skillNames[i];
                var b = skillNames[j];
                var wordsA = new HashSet<string>(descriptions[a].Split(' ', StringSplitOptions.RemoveEmptyEntries));
                var wordsB = new HashSet<string>(descriptions[b].Split(' ', StringSplitOptions.RemoveEmptyEntries));
                wordsA.ExceptWith(stopWords);
                wordsB.ExceptWith(stopWords);
                var shared = new HashSet<string>(wordsA);
                shared.IntersectWith(wordsB);
                if (shared.Count >= 3)
                {
                    overlaps.Add(new Dictionary<string, object>
                    {
                        ["skill_a"] = a,
                        ["skill_b"] = b,
                        ["shared_keywords"] = shared.OrderBy(w => w).ToList(),
                        ["shared_count"] = shared.Count,
                    });
                }
            }
        }
        overlaps.Sort((x, y) => ((int)y["shared_count"]).CompareTo((int)x["shared_count"]));

        // Attention budget statistics
        var tokenCounts = skills
            .Where(s => !string.IsNullOrEmpty(s.Description))
            .Select(s => s.DescriptionTokens)
            .ToList();

        int totalTokens = tokenCounts.Sum();
        double meanTokens = tokenCounts.Count > 0 ? (double)totalTokens / tokenCounts.Count : 0;
        var sortedCounts = tokenCounts.OrderBy(x => x).ToList();
        int medianTokens = sortedCounts.Count > 0 ? sortedCounts[sortedCounts.Count / 2] : 0;
        int maxTokens = sortedCounts.Count > 0 ? sortedCounts[^1] : 0;
        int minTokens = sortedCounts.Count > 0 ? sortedCounts[0] : 0;

        var skillsAbove2xMedian = skills
            .Where(s => s.DescriptionTokens > medianTokens * 2 && medianTokens > 0)
            .Select(s => s.Name!)
            .ToList();

        // Per-project attention budget
        var globalSkills = skills.Where(s => s.Scope == "global").ToList();
        int globalTokens = globalSkills
            .Where(s => !string.IsNullOrEmpty(s.Description))
            .Sum(s => s.DescriptionTokens);

        var projectPaths = skills
            .Where(s => s.Scope == "project-local" && !string.IsNullOrEmpty(s.ProjectPath))
            .Select(s => s.ProjectPath!)
            .Distinct()
            .OrderBy(p => p)
            .ToList();

        var projectBudgets = new Dictionary<string, object>();
        foreach (var pp in projectPaths)
        {
            var localSkills = skills.Where(s => s.ProjectPath == pp).ToList();
            int localTokens = localSkills
                .Where(s => !string.IsNullOrEmpty(s.Description))
                .Sum(s => s.DescriptionTokens);
            projectBudgets[pp] = new Dictionary<string, object>
            {
                ["global_tokens"] = globalTokens,
                ["local_tokens"] = localTokens,
                ["total_tokens"] = globalTokens + localTokens,
                ["local_skill_names"] = localSkills.Select(s => s.Name!).ToList(),
            };
        }

        var allDirs = globalDirs.Concat(projectSkillDirs.Select(d => d.Item1)).ToList();

        var byCategory = CountBy(skills, s => s.Category);
        var byScopeDict = CountBy(skills, s => s.Scope);

        var skillsWithoutDescription = skills
            .Where(s => string.IsNullOrEmpty(s.Description))
            .Select(s => s.Name!)
            .ToList();

        return new Dictionary<string, object?>
        {
            ["collected_at"] = DateTimeOffset.UtcNow.ToString("o"),
            ["skill_dirs_scanned"] = allDirs,
            ["skills"] = skills,
            ["summary"] = new Dictionary<string, object>
            {
                ["total_skills"] = skills.Count,
                ["by_category"] = byCategory,
                ["by_scope"] = byScopeDict,
                ["skills_without_description"] = skillsWithoutDescription,
            },
            ["attention_budget"] = new Dictionary<string, object>
            {
                ["total_description_tokens"] = totalTokens,
                ["global_description_tokens"] = globalTokens,
                ["mean_tokens_per_skill"] = Math.Round(meanTokens, 1),
                ["median_tokens_per_skill"] = medianTokens,
                ["max_tokens"] = maxTokens,
                ["min_tokens"] = minTokens,
                ["skills_above_2x_median"] = skillsAbove2xMedian,
                ["per_project"] = projectBudgets,
            },
            ["description_overlaps"] = overlaps,
        };
    }

    private static Dictionary<string, int> CountBy(List<SkillInfo> items, Func<SkillInfo, string> keySelector)
    {
        var counts = new Dictionary<string, int>();
        foreach (var item in items)
        {
            var key = keySelector(item) ?? "unknown";
            counts[key] = counts.GetValueOrDefault(key) + 1;
        }
        return counts;
    }
}

/// <summary>JSON output helpers using Utf8JsonWriter.</summary>
class JsonOutput
{
    public static void WriteManifest(Utf8JsonWriter w, Dictionary<string, object?> manifest)
    {
        w.WriteStartObject();

        w.WriteString("collected_at", (string)manifest["collected_at"]!);

        w.WritePropertyName("skill_dirs_scanned");
        WriteStringList(w, (List<string>)manifest["skill_dirs_scanned"]!);

        w.WritePropertyName("skills");
        WriteSkillsArray(w, (List<SkillInfo>)manifest["skills"]!);

        w.WritePropertyName("summary");
        WriteSummary(w, (Dictionary<string, object>)manifest["summary"]!);

        w.WritePropertyName("attention_budget");
        WriteAttentionBudget(w, (Dictionary<string, object>)manifest["attention_budget"]!);

        w.WritePropertyName("description_overlaps");
        WriteOverlaps(w, (List<Dictionary<string, object>>)manifest["description_overlaps"]!);

        w.WriteEndObject();
    }

    public static void WriteStringList(Utf8JsonWriter w, List<string> list)
    {
        w.WriteStartArray();
        foreach (var item in list) w.WriteStringValue(item);
        w.WriteEndArray();
    }

    private static void WriteSkillsArray(Utf8JsonWriter w, List<SkillInfo> skills)
    {
        w.WriteStartArray();
        foreach (var s in skills)
        {
            w.WriteStartObject();

            if (s.Error != null)
            {
                w.WriteString("error", s.Error);
                w.WriteString("filepath", s.Filepath);
                w.WriteEndObject();
                continue;
            }

            w.WriteString("filepath", s.Filepath);
            if (s.FilepathResolved != null)
                w.WriteString("filepath_resolved", s.FilepathResolved);
            else
                w.WriteNull("filepath_resolved");

            w.WriteString("name", s.Name);
            if (s.Description != null)
                w.WriteString("description", s.Description);
            else
                w.WriteNull("description");
            if (s.Trigger != null)
                w.WriteString("trigger", s.Trigger);
            else
                w.WriteNull("trigger");
            if (s.BodyPreview != null)
                w.WriteString("body_preview", s.BodyPreview);
            else
                w.WriteNull("body_preview");
            w.WriteNumber("full_content_length", s.FullContentLength);
            w.WriteString("description_raw", s.DescriptionRaw ?? "");
            w.WriteBoolean("disable_model_invocation", s.DisableModelInvocation);
            w.WriteNumber("description_tokens", s.DescriptionTokens);
            w.WriteString("category", s.Category);
            w.WriteString("scope", s.Scope);
            if (s.ProjectPath != null)
                w.WriteString("project_path", s.ProjectPath);
            else
                w.WriteNull("project_path");

            w.WriteEndObject();
        }
        w.WriteEndArray();
    }

    private static void WriteSummary(Utf8JsonWriter w, Dictionary<string, object> summary)
    {
        w.WriteStartObject();
        w.WriteNumber("total_skills", (int)summary["total_skills"]);

        w.WritePropertyName("by_category");
        w.WriteStartObject();
        foreach (var (k, v) in (Dictionary<string, int>)summary["by_category"])
            w.WriteNumber(k, v);
        w.WriteEndObject();

        w.WritePropertyName("by_scope");
        w.WriteStartObject();
        foreach (var (k, v) in (Dictionary<string, int>)summary["by_scope"])
            w.WriteNumber(k, v);
        w.WriteEndObject();

        w.WritePropertyName("skills_without_description");
        WriteStringList(w, (List<string>)summary["skills_without_description"]);

        w.WriteEndObject();
    }

    private static void WriteAttentionBudget(Utf8JsonWriter w, Dictionary<string, object> budget)
    {
        w.WriteStartObject();
        w.WriteNumber("total_description_tokens", (int)budget["total_description_tokens"]);
        w.WriteNumber("global_description_tokens", (int)budget["global_description_tokens"]);
        w.WriteNumber("mean_tokens_per_skill", (double)budget["mean_tokens_per_skill"]);
        w.WriteNumber("median_tokens_per_skill", (int)budget["median_tokens_per_skill"]);
        w.WriteNumber("max_tokens", (int)budget["max_tokens"]);
        w.WriteNumber("min_tokens", (int)budget["min_tokens"]);

        w.WritePropertyName("skills_above_2x_median");
        WriteStringList(w, (List<string>)budget["skills_above_2x_median"]);

        w.WritePropertyName("per_project");
        w.WriteStartObject();
        foreach (var (pp, pbObj) in (Dictionary<string, object>)budget["per_project"])
        {
            w.WritePropertyName(pp);
            var pb = (Dictionary<string, object>)pbObj;
            w.WriteStartObject();
            w.WriteNumber("global_tokens", (int)pb["global_tokens"]);
            w.WriteNumber("local_tokens", (int)pb["local_tokens"]);
            w.WriteNumber("total_tokens", (int)pb["total_tokens"]);
            w.WritePropertyName("local_skill_names");
            WriteStringList(w, (List<string>)pb["local_skill_names"]);
            w.WriteEndObject();
        }
        w.WriteEndObject();

        w.WriteEndObject();
    }

    private static void WriteOverlaps(Utf8JsonWriter w, List<Dictionary<string, object>> overlaps)
    {
        w.WriteStartArray();
        foreach (var o in overlaps)
        {
            w.WriteStartObject();
            w.WriteString("skill_a", (string)o["skill_a"]);
            w.WriteString("skill_b", (string)o["skill_b"]);
            w.WritePropertyName("shared_keywords");
            WriteStringList(w, (List<string>)o["shared_keywords"]);
            w.WriteNumber("shared_count", (int)o["shared_count"]);
            w.WriteEndObject();
        }
        w.WriteEndArray();
    }
}
