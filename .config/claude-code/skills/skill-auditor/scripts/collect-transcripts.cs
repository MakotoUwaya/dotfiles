#!/usr/bin/env dotnet-script
#nullable enable
// collect-transcripts.cs — Collect and parse Claude Code session transcripts.
//
// Reads .jsonl session files from ~/.claude/projects/ and produces a structured
// JSON file suitable for routing analysis.
//
// Usage:
//     dotnet script collect-transcripts.cs <project-path> [options]
//
// Arguments:
//     project-path    Path to a Claude project directory under ~/.claude/projects/,
//                     OR a direct project working directory (auto-resolves the
//                     encoded path). Use "all" to scan all projects.
//
// Options:
//     --days N        Only include sessions from the last N days (default: 14)
//     --output PATH   Output file path (default: ./transcripts.json)
//     --min-turns N   Skip sessions with fewer than N user turns (default: 1)
//     --verbose       Print progress and parsing details
//     --list          List all available projects and exit
//     --cwd DIR       Working directory to auto-detect project from

using System;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.Encodings.Web;
using System.Text.Json;

// ── Built-in commands ────────────────────────────────────────────────────────
var ClaudeBuiltinCommands = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
{
    "help", "clear", "compact", "model", "usage", "cost", "login", "logout",
    "status", "config", "permissions", "doctor", "review", "init", "memory",
    "mcp", "fast", "slow", "vim", "emacs", "terminal-setup", "tools", "tasks",
    "bug", "quit", "exit", "diff", "undo", "resume", "ide", "add-dir",
    "release-notes", "listen", "pr-comments",
};

// ── CLI argument parsing ─────────────────────────────────────────────────────
string? positionalProjectPath = null;
string? cwdArg = null;
bool listProjects = false;
int days = 14;
string outputPath = "./transcripts.json";
int minTurns = 1;
bool verbose = false;

{
    var a = Args.ToArray();
    for (int i = 0; i < a.Length; i++)
    {
        switch (a[i])
        {
            case "--list":
                listProjects = true;
                break;
            case "--verbose":
                verbose = true;
                break;
            case "--days":
                if (i + 1 < a.Length) days = int.Parse(a[++i]);
                break;
            case "--output":
                if (i + 1 < a.Length) outputPath = a[++i];
                break;
            case "--min-turns":
                if (i + 1 < a.Length) minTurns = int.Parse(a[++i]);
                break;
            case "--cwd":
                if (i + 1 < a.Length) cwdArg = a[++i];
                break;
            default:
                if (!a[i].StartsWith("-") && positionalProjectPath == null)
                    positionalProjectPath = a[i];
                break;
        }
    }
}

// ── Helper: Claude projects base dir ─────────────────────────────────────────
string ClaudeProjectsDir()
{
    return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".claude", "projects");
}

// ── Encode project path ──────────────────────────────────────────────────────
string EncodeProjectPath(string workingDir)
{
    string absPath = Path.GetFullPath(Environment.ExpandEnvironmentVariables(
        workingDir.StartsWith("~")
            ? Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), workingDir.Substring(1).TrimStart('/'))
            : workingDir));
    string encoded = absPath.Replace("/", "-").Replace(".", "-");
    if (!encoded.StartsWith("-"))
        encoded = "-" + encoded;
    return encoded;
}

// ── Find project directories ─────────────────────────────────────────────────
List<string> FindProjectDir(string projectPath)
{
    string claudeProjects = ClaudeProjectsDir();

    if (projectPath == "all")
    {
        if (!Directory.Exists(claudeProjects)) return new List<string>();
        return Directory.GetDirectories(claudeProjects).ToList();
    }

    // Direct path to a claude projects subdirectory
    if (Directory.Exists(projectPath) && projectPath.StartsWith(claudeProjects))
        return new List<string> { projectPath };

    // Path under ~/.claude/projects/ by name
    string direct = Path.Combine(claudeProjects, projectPath);
    if (Directory.Exists(direct))
        return new List<string> { direct };

    // Working directory — encode it and try exact match
    string encoded = EncodeProjectPath(projectPath);
    string encodedPath = Path.Combine(claudeProjects, encoded);
    if (Directory.Exists(encodedPath))
        return new List<string> { encodedPath };

    // Fuzzy: try without trailing dash (backward compat)
    string encodedTrail = encoded.EndsWith("-") ? encoded.TrimEnd('-') : encoded + "-";
    string altPath = Path.Combine(claudeProjects, encodedTrail);
    if (Directory.Exists(altPath))
        return new List<string> { altPath };

    return new List<string>();
}

// ── Auto-detect project from cwd ─────────────────────────────────────────────
string? AutoDetectProject(string cwd)
{
    string claudeProjects = ClaudeProjectsDir();
    if (!Directory.Exists(claudeProjects)) return null;

    var available = new HashSet<string>(
        Directory.GetDirectories(claudeProjects).Select(Path.GetFileName)!);

    string absCwd = Path.GetFullPath(cwd);

    // Exact match
    string encoded = EncodeProjectPath(absCwd);
    string encodedName = Path.GetFileName(encoded) ?? encoded;
    if (available.Contains(encodedName))
        return Path.Combine(claudeProjects, encodedName);

    // Walk up parent directories
    string? current = absCwd;
    while (current != null)
    {
        string? parent = Path.GetDirectoryName(current);
        if (parent == null || parent == current) break;
        current = parent;

        string encodedParent = EncodeProjectPath(current);
        string name = Path.GetFileName(encodedParent) ?? encodedParent;
        if (available.Contains(name))
        {
            if (verbose)
                Console.Error.WriteLine($"  Auto-detected project: {name} (from parent of cwd)");
            return Path.Combine(claudeProjects, name);
        }
    }

    return null;
}

// ── List available projects ──────────────────────────────────────────────────
List<Dictionary<string, object>> ListAvailableProjects()
{
    string claudeProjects = ClaudeProjectsDir();
    var result = new List<Dictionary<string, object>>();
    if (!Directory.Exists(claudeProjects)) return result;

    foreach (string dir in Directory.GetDirectories(claudeProjects).OrderBy(d => d))
    {
        string name = Path.GetFileName(dir)!;
        string decoded = name.Replace("-", "/");
        if (!decoded.StartsWith("/")) decoded = "/" + decoded;

        int sessionCount = Directory.EnumerateFiles(dir, "*.jsonl").Count();

        result.Add(new Dictionary<string, object>
        {
            ["encoded"] = name,
            ["decoded"] = decoded,
            ["path"] = dir,
            ["session_count"] = sessionCount,
        });
    }
    return result;
}

// ── Normalize JSONL line ─────────────────────────────────────────────────────
JsonElement NormalizeJsonlLine(JsonElement obj)
{
    if (obj.ValueKind != JsonValueKind.Object) return obj;
    if (!obj.TryGetProperty("message", out JsonElement inner) || inner.ValueKind != JsonValueKind.Object)
        return obj;

    var dict = new Dictionary<string, JsonElement>();

    // Preserve envelope-level fields
    string[] envelopeKeys = { "type", "timestamp", "sessionId", "cwd", "uuid",
                              "parentUuid", "userType", "requestId" };
    foreach (string key in envelopeKeys)
    {
        if (obj.TryGetProperty(key, out JsonElement val))
            dict[key] = val.Clone();
    }

    // Promote inner message fields to top level
    string[] innerKeys = { "role", "content", "model", "id", "stop_reason",
                           "stop_sequence", "usage" };
    foreach (string key in innerKeys)
    {
        if (inner.TryGetProperty(key, out JsonElement val))
        {
            if (key == "type" && dict.ContainsKey("type"))
                continue;
            dict[key] = val.Clone();
        }
    }

    // Ensure "role" is set
    if (!dict.ContainsKey("role"))
    {
        string outerType = obj.TryGetProperty("type", out JsonElement typeEl) ? typeEl.GetString() ?? "" : "";
        var roleMap = new Dictionary<string, string>
        {
            ["human"] = "user", ["user"] = "user",
            ["assistant"] = "assistant", ["tool_result"] = "tool"
        };
        string role = roleMap.ContainsKey(outerType) ? roleMap[outerType] : outerType;
        dict["role"] = JsonDocument.Parse($"\"{EscapeJsonString(role)}\"").RootElement.Clone();
    }

    // Rebuild as a JsonElement
    using var ms = new MemoryStream();
    using (var w = new Utf8JsonWriter(ms))
    {
        w.WriteStartObject();
        foreach (var kv in dict)
        {
            w.WritePropertyName(kv.Key);
            kv.Value.WriteTo(w);
        }
        w.WriteEndObject();
    }
    return JsonDocument.Parse(ms.ToArray()).RootElement.Clone();
}

string EscapeJsonString(string s) => s.Replace("\\", "\\\\").Replace("\"", "\\\"");

// ── Extract timestamp ────────────────────────────────────────────────────────
string? ExtractTimestamp(JsonElement msg)
{
    foreach (string key in new[] { "timestamp", "created_at", "ts" })
    {
        if (msg.TryGetProperty(key, out JsonElement val))
        {
            if (val.ValueKind == JsonValueKind.String)
                return val.GetString();
            if (val.ValueKind == JsonValueKind.Number)
                return val.GetRawText();
        }
    }
    return null;
}

// ── Check skill load ─────────────────────────────────────────────────────────
void CheckSkillLoad(JsonElement toolCall, List<string> skillsLoaded)
{
    string name = toolCall.TryGetProperty("name", out JsonElement nameEl) ? nameEl.GetString() ?? "" : "";
    JsonElement inp = toolCall.TryGetProperty("input", out JsonElement inputEl) ? inputEl : default;

    if (name == "view" || name == "Read" || name == "read_file")
    {
        string path = "";
        if (inp.ValueKind == JsonValueKind.Object)
        {
            if (inp.TryGetProperty("path", out JsonElement pathEl))
                path = pathEl.GetString() ?? "";
            else if (inp.TryGetProperty("file_path", out JsonElement fpEl))
                path = fpEl.GetString() ?? "";
        }
        if (path.Contains("SKILL.md"))
            skillsLoaded.Add(path);
    }

    if (name == "bash" || name == "bash_tool" || name == "execute_command")
    {
        string cmd = "";
        if (inp.ValueKind == JsonValueKind.Object)
        {
            if (inp.TryGetProperty("command", out JsonElement cmdEl))
                cmd = cmdEl.GetString() ?? "";
            else if (inp.TryGetProperty("cmd", out JsonElement cmdEl2))
                cmd = cmdEl2.GetString() ?? "";
        }
        if (cmd.Contains("SKILL.md"))
        {
            foreach (string token in cmd.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries))
            {
                if (token.Contains("SKILL.md"))
                {
                    skillsLoaded.Add(token);
                    break;
                }
            }
        }
    }
}

// ── Extract skills from message ──────────────────────────────────────────────
void ExtractSkillsFromMsg(JsonElement msg, List<string> skillsList)
{
    string msgType = "";
    if (msg.TryGetProperty("type", out JsonElement typeEl))
        msgType = typeEl.GetString() ?? "";
    else if (msg.TryGetProperty("role", out JsonElement roleEl))
        msgType = roleEl.GetString() ?? "";

    if (msgType == "assistant")
    {
        if (msg.TryGetProperty("content", out JsonElement content) && content.ValueKind == JsonValueKind.Array)
        {
            foreach (JsonElement block in content.EnumerateArray())
            {
                if (block.ValueKind == JsonValueKind.Object
                    && block.TryGetProperty("type", out JsonElement bt)
                    && bt.GetString() == "tool_use")
                {
                    CheckSkillLoad(block, skillsList);
                }
            }
        }
    }

    if (msgType == "tool_use")
        CheckSkillLoad(msg, skillsList);

    if (msg.TryGetProperty("tool_calls", out JsonElement tcArr) && tcArr.ValueKind == JsonValueKind.Array)
    {
        foreach (JsonElement tc in tcArr.EnumerateArray())
        {
            if (tc.ValueKind == JsonValueKind.Object)
                CheckSkillLoad(tc, skillsList);
        }
    }
}

// ── Extract text from user content ───────────────────────────────────────────
string ExtractUserText(JsonElement msg)
{
    if (!msg.TryGetProperty("content", out JsonElement content))
        return "";

    if (content.ValueKind == JsonValueKind.String)
        return content.GetString()?.Trim() ?? "";

    if (content.ValueKind == JsonValueKind.Array)
    {
        var parts = new List<string>();
        foreach (JsonElement p in content.EnumerateArray())
        {
            if (p.ValueKind == JsonValueKind.Object
                && p.TryGetProperty("type", out JsonElement pt)
                && pt.GetString() == "text"
                && p.TryGetProperty("text", out JsonElement textEl))
            {
                string t = textEl.GetString() ?? "";
                if (!string.IsNullOrEmpty(t)) parts.Add(t);
            }
        }
        return string.Join(" ", parts).Trim();
    }

    return "";
}

// ── Is builtin command ───────────────────────────────────────────────────────
bool IsBuiltinCommand(string msg)
{
    msg = msg.Trim();
    if (!msg.StartsWith("/")) return false;
    string cmd = msg.TrimStart('/').Split((char[]?)null, 2, StringSplitOptions.RemoveEmptyEntries).FirstOrDefault() ?? "";
    cmd = cmd.Split('\n')[0].ToLowerInvariant();
    return ClaudeBuiltinCommands.Contains(cmd);
}

// ── Get message type ─────────────────────────────────────────────────────────
string GetMsgType(JsonElement msg)
{
    if (msg.TryGetProperty("type", out JsonElement typeEl))
        return typeEl.GetString() ?? "";
    if (msg.TryGetProperty("role", out JsonElement roleEl))
        return roleEl.GetString() ?? "";
    return "";
}

// ── Build turn_skill_map ─────────────────────────────────────────────────────
List<Dictionary<string, object>> BuildTurnSkillMap(List<JsonElement> messages)
{
    var result = new List<Dictionary<string, object>>();
    int turnIndex = 0;
    string? currentUserMsg = null;
    var skillsSinceLastTurn = new List<string>();

    foreach (JsonElement msg in messages)
    {
        string msgType = GetMsgType(msg);

        if (msgType == "human" || msgType == "user")
        {
            if (currentUserMsg != null)
            {
                result.Add(new Dictionary<string, object>
                {
                    ["turn_index"] = turnIndex,
                    ["user_message"] = currentUserMsg,
                    ["skills_loaded_after"] = Dedupe(skillsSinceLastTurn),
                    ["is_builtin_command"] = IsBuiltinCommand(currentUserMsg),
                });
                turnIndex++;
            }

            currentUserMsg = ExtractUserText(msg);
            skillsSinceLastTurn = new List<string>();
        }
        else
        {
            ExtractSkillsFromMsg(msg, skillsSinceLastTurn);
        }
    }

    if (currentUserMsg != null)
    {
        result.Add(new Dictionary<string, object>
        {
            ["turn_index"] = turnIndex,
            ["user_message"] = currentUserMsg,
            ["skills_loaded_after"] = Dedupe(skillsSinceLastTurn),
            ["is_builtin_command"] = IsBuiltinCommand(currentUserMsg),
        });
    }

    return result;
}

List<string> Dedupe(List<string> items)
{
    var seen = new HashSet<string>();
    var result = new List<string>();
    foreach (string item in items)
    {
        if (seen.Add(item)) result.Add(item);
    }
    return result;
}

// ── Extract project dir from filepath ────────────────────────────────────────
string? ExtractProjectDir(string sessionFilepath)
{
    string[] parts = sessionFilepath.Split(Path.DirectorySeparatorChar, Path.AltDirectorySeparatorChar);
    for (int i = 0; i < parts.Length; i++)
    {
        if (parts[i] == "projects" && i + 1 < parts.Length)
            return parts[i + 1];
    }
    return null;
}

// ── Parse a single JSONL session ─────────────────────────────────────────────
Dictionary<string, object>? ParseJsonlSession(string filepath)
{
    string sessionId = Path.GetFileNameWithoutExtension(filepath);
    var messages = new List<JsonElement>();
    var skillsLoaded = new List<string>();
    var userTurns = new List<string>();
    var errors = new List<string>();

    try
    {
        using var reader = new StreamReader(filepath, Encoding.UTF8);
        int lineNum = 0;
        string? line;
        while ((line = reader.ReadLine()) != null)
        {
            lineNum++;
            line = line.Trim();
            if (string.IsNullOrEmpty(line)) continue;

            try
            {
                using var doc = JsonDocument.Parse(line);
                JsonElement normalized = NormalizeJsonlLine(doc.RootElement.Clone());
                messages.Add(normalized);
            }
            catch (JsonException e)
            {
                errors.Add($"Line {lineNum}: {e.Message}");
            }
        }
    }
    catch (Exception e)
    {
        if (verbose) Console.Error.WriteLine($"  ERROR reading {filepath}: {e.Message}");
        return null;
    }

    if (messages.Count == 0) return null;

    // Extract user turns and skill loads
    foreach (JsonElement msg in messages)
    {
        string msgType = GetMsgType(msg);

        if (msgType == "human" || msgType == "user")
        {
            string text = ExtractUserText(msg);
            if (!string.IsNullOrEmpty(text))
                userTurns.Add(text);
        }

        if (msgType == "assistant")
        {
            if (msg.TryGetProperty("content", out JsonElement content) && content.ValueKind == JsonValueKind.Array)
            {
                foreach (JsonElement block in content.EnumerateArray())
                {
                    if (block.ValueKind == JsonValueKind.Object
                        && block.TryGetProperty("type", out JsonElement bt)
                        && bt.GetString() == "tool_use")
                    {
                        CheckSkillLoad(block, skillsLoaded);
                    }
                }
            }
        }

        if (msgType == "tool_use")
            CheckSkillLoad(msg, skillsLoaded);

        if (msg.TryGetProperty("tool_calls", out JsonElement tcArr) && tcArr.ValueKind == JsonValueKind.Array)
        {
            foreach (JsonElement tc in tcArr.EnumerateArray())
            {
                if (tc.ValueKind == JsonValueKind.Object)
                    CheckSkillLoad(tc, skillsLoaded);
            }
        }
    }

    string? firstTs = messages.Count > 0 ? ExtractTimestamp(messages[0]) : null;
    string? lastTs = messages.Count > 0 ? ExtractTimestamp(messages[^1]) : null;

    var result = new Dictionary<string, object>
    {
        ["session_id"] = sessionId,
        ["filepath"] = filepath,
        ["messages"] = messages,
        ["skills_loaded"] = Dedupe(skillsLoaded),
        ["user_turns"] = userTurns,
        ["first_timestamp"] = (object?)firstTs ?? "",
        ["last_timestamp"] = (object?)lastTs ?? "",
        ["message_count"] = messages.Count,
        ["user_turn_count"] = userTurns.Count,
    };

    if (errors.Count > 0 && verbose)
    {
        Console.Error.WriteLine($"  WARN {sessionId}: {errors.Count} parse errors");
        result["parse_errors"] = errors;
    }

    return result;
}

// ── Filter sessions by date ──────────────────────────────────────────────────
List<Dictionary<string, object>> FilterByDate(List<Dictionary<string, object>> sessions, int daysFilter)
{
    var cutoff = DateTimeOffset.UtcNow - TimeSpan.FromDays(daysFilter);
    var filtered = new List<Dictionary<string, object>>();

    foreach (var s in sessions)
    {
        object tsObj = s.ContainsKey("first_timestamp") ? s["first_timestamp"] : "";
        string? ts = tsObj as string;
        if (string.IsNullOrEmpty(ts))
        {
            filtered.Add(s);
            continue;
        }

        // Try ISO 8601
        if (DateTimeOffset.TryParse(ts.Replace("Z", "+00:00"), CultureInfo.InvariantCulture, DateTimeStyles.None, out DateTimeOffset dt))
        {
            if (dt >= cutoff) filtered.Add(s);
            continue;
        }

        // Try unix timestamp (seconds or milliseconds)
        if (double.TryParse(ts, NumberStyles.Float, CultureInfo.InvariantCulture, out double numericTs))
        {
            DateTimeOffset dtFromNum;
            if (numericTs > 1e12) // milliseconds
                dtFromNum = DateTimeOffset.FromUnixTimeMilliseconds((long)numericTs);
            else
                dtFromNum = DateTimeOffset.FromUnixTimeSeconds((long)numericTs);
            if (dtFromNum >= cutoff) filtered.Add(s);
            continue;
        }

        // Can't parse — include it
        filtered.Add(s);
    }

    return filtered;
}

// ── Main collect function ────────────────────────────────────────────────────
Dictionary<string, object> Collect(string projectPath, int daysFilter, int minTurnsFilter)
{
    var projectDirs = FindProjectDir(projectPath);
    if (projectDirs.Count == 0)
    {
        return new Dictionary<string, object>
        {
            ["error"] = $"No project directory found for: {projectPath}",
            ["hint"] = "Check ~/.claude/projects/ for available projects, or use 'all' to scan everything.",
        };
    }

    var allSessions = new List<Dictionary<string, object>>();
    var parseErrors = new List<string>();

    foreach (string pdir in projectDirs)
    {
        var jsonlFiles = Directory.EnumerateFiles(pdir, "*.jsonl").OrderBy(f => f).ToList();
        if (verbose)
            Console.Error.WriteLine($"Scanning {pdir}: {jsonlFiles.Count} session files");

        foreach (string fp in jsonlFiles)
        {
            if (Path.GetFileName(fp) == "history.jsonl") continue;

            var session = ParseJsonlSession(fp);
            if (session == null)
            {
                parseErrors.Add(fp);
                continue;
            }

            if ((int)session["user_turn_count"] >= minTurnsFilter)
                allSessions.Add(session);
        }
    }

    if (daysFilter > 0)
    {
        int before = allSessions.Count;
        allSessions = FilterByDate(allSessions, daysFilter);
        if (verbose)
            Console.Error.WriteLine($"Date filter: {before} -> {allSessions.Count} sessions (last {daysFilter} days)");
    }

    // Sort descending by first_timestamp
    allSessions.Sort((a, b) =>
    {
        string tsA = a.ContainsKey("first_timestamp") ? a["first_timestamp"]?.ToString() ?? "" : "";
        string tsB = b.ContainsKey("first_timestamp") ? b["first_timestamp"]?.ToString() ?? "" : "";
        return string.Compare(tsB, tsA, StringComparison.Ordinal);
    });

    var allSkills = new HashSet<string>();
    int totalTurns = 0;
    foreach (var s in allSessions)
    {
        foreach (string sk in (List<string>)s["skills_loaded"])
            allSkills.Add(sk);
        totalTurns += (int)s["user_turn_count"];
    }

    // Build slim sessions with turn_skill_map
    var sessionsSlim = new List<Dictionary<string, object>>();
    foreach (var s in allSessions)
    {
        var slim = new Dictionary<string, object>();
        foreach (var kv in s)
        {
            if (kv.Key != "messages" && kv.Key != "user_turns")
                slim[kv.Key] = kv.Value;
        }
        var turnSkillMap = BuildTurnSkillMap((List<JsonElement>)s["messages"]);
        slim["turn_skill_map"] = turnSkillMap;
        slim["project_dir"] = (object?)ExtractProjectDir((string)s["filepath"]) ?? "";
        sessionsSlim.Add(slim);
    }

    // Per-project session counts
    var sessionsByProject = new Dictionary<string, int>();
    foreach (var s in sessionsSlim)
    {
        string pdir = s.ContainsKey("project_dir") ? s["project_dir"]?.ToString() ?? "unknown" : "unknown";
        sessionsByProject[pdir] = sessionsByProject.GetValueOrDefault(pdir, 0) + 1;
    }

    return new Dictionary<string, object>
    {
        ["project_path"] = projectPath,
        ["collected_at"] = DateTimeOffset.UtcNow.ToString("o"),
        ["config"] = new Dictionary<string, object>
        {
            ["days"] = daysFilter,
            ["min_turns"] = minTurnsFilter,
        },
        ["sessions"] = sessionsSlim,
        ["summary"] = new Dictionary<string, object>
        {
            ["total_sessions"] = sessionsSlim.Count,
            ["total_user_turns"] = totalTurns,
            ["unique_skills_loaded"] = allSkills.OrderBy(s => s).ToList(),
            ["skills_never_loaded"] = new List<string>(),
            ["parse_errors"] = parseErrors.Count,
            ["sessions_by_project"] = sessionsByProject,
        },
        ["parse_error_files"] = parseErrors.Count > 0 ? parseErrors : new List<string>(),
    };
}

// ── JSON writer helpers ──────────────────────────────────────────────────────
void WriteValue(Utf8JsonWriter w, object? value)
{
    switch (value)
    {
        case null:
            w.WriteNullValue();
            break;
        case string s:
            w.WriteStringValue(s);
            break;
        case int i:
            w.WriteNumberValue(i);
            break;
        case long l:
            w.WriteNumberValue(l);
            break;
        case double d:
            w.WriteNumberValue(d);
            break;
        case bool b:
            w.WriteBooleanValue(b);
            break;
        case JsonElement je:
            je.WriteTo(w);
            break;
        case List<string> ls:
            w.WriteStartArray();
            foreach (string item in ls) w.WriteStringValue(item);
            w.WriteEndArray();
            break;
        case List<JsonElement> lj:
            w.WriteStartArray();
            foreach (JsonElement item in lj) item.WriteTo(w);
            w.WriteEndArray();
            break;
        case List<Dictionary<string, object>> ld:
            w.WriteStartArray();
            foreach (var dict in ld) WriteDict(w, dict);
            w.WriteEndArray();
            break;
        case Dictionary<string, object> dict:
            WriteDict(w, dict);
            break;
        case Dictionary<string, int> di:
            w.WriteStartObject();
            foreach (var kv in di)
            {
                w.WritePropertyName(kv.Key);
                w.WriteNumberValue(kv.Value);
            }
            w.WriteEndObject();
            break;
        default:
            w.WriteStringValue(value.ToString());
            break;
    }
}

void WriteDict(Utf8JsonWriter w, Dictionary<string, object> dict)
{
    w.WriteStartObject();
    foreach (var kv in dict)
    {
        w.WritePropertyName(kv.Key);
        WriteValue(w, kv.Value);
    }
    w.WriteEndObject();
}

string SerializeResult(Dictionary<string, object> result)
{
    using var ms = new MemoryStream();
    using (var w = new Utf8JsonWriter(ms, new JsonWriterOptions
    {
        Indented = true,
        Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping,
    }))
    {
        WriteDict(w, result);
    }
    return Encoding.UTF8.GetString(ms.ToArray());
}

// ── Main entry point ─────────────────────────────────────────────────────────
if (listProjects)
{
    var projects = ListAvailableProjects();
    if (projects.Count == 0)
    {
        Console.Error.WriteLine("No projects found in ~/.claude/projects/");
        Environment.Exit(1);
    }
    Console.WriteLine($"Found {projects.Count} projects:\n");
    foreach (var p in projects)
    {
        Console.WriteLine($"  {p["decoded"]}");
        Console.WriteLine($"    encoded: {p["encoded"]}");
        Console.WriteLine($"    sessions: {p["session_count"]}");
        Console.WriteLine();
    }
    Environment.Exit(0);
}

string? projectPathResolved = positionalProjectPath;

if (projectPathResolved == null && cwdArg != null)
{
    string? detected = AutoDetectProject(cwdArg);
    if (detected != null)
    {
        projectPathResolved = detected;
        Console.Error.WriteLine($"Auto-detected project: {Path.GetFileName(detected)}");
    }
    else
    {
        Console.Error.WriteLine($"ERROR: Could not auto-detect project from cwd: {cwdArg}");
        Console.Error.WriteLine("\nAvailable projects:");
        foreach (var p in ListAvailableProjects())
            Console.Error.WriteLine($"  {p["decoded"]}  ({p["session_count"]} sessions)");
        Environment.Exit(1);
    }
}
else if (projectPathResolved == null)
{
    Console.Error.WriteLine("ERROR: No project path specified. Use a path argument, --cwd for auto-detect, or --list to see available projects.");
    Environment.Exit(1);
}

var collectResult = Collect(projectPathResolved!, days, minTurns);

if (collectResult.ContainsKey("error"))
{
    Console.Error.WriteLine(SerializeResult(collectResult));
    Environment.Exit(1);
}

string outputDir = Path.GetDirectoryName(Path.GetFullPath(outputPath)) ?? ".";
Directory.CreateDirectory(outputDir);
File.WriteAllText(outputPath, SerializeResult(collectResult), Encoding.UTF8);

var summary = (Dictionary<string, object>)collectResult["summary"];
Console.WriteLine(
    $"Collected {summary["total_sessions"]} sessions, " +
    $"{summary["total_user_turns"]} user turns, " +
    $"{((List<string>)summary["unique_skills_loaded"]).Count} unique skills loaded");
int parseErrorCount = (int)summary["parse_errors"];
if (parseErrorCount > 0)
    Console.WriteLine($"  ({parseErrorCount} sessions had parse errors)");
Console.WriteLine($"Output: {outputPath}");
