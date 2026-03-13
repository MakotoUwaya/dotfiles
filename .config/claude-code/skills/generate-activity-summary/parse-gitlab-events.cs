using System.Text.Json;

var json = Console.In.ReadToEnd();
var events = JsonDocument.Parse(json).RootElement;

foreach (var e in events.EnumerateArray())
{
    var action = e.GetProperty("action_name").GetString() ?? "";
    var targetType = e.GetProperty("target_type").GetString() ?? "";
    var targetTitle = e.GetProperty("target_title").GetString() ?? "";
    var created = e.GetProperty("created_at").GetString() ?? "";

    if (e.TryGetProperty("push_data", out var push) && push.ValueKind == JsonValueKind.Object)
    {
        var refName = push.TryGetProperty("ref", out var r) ? r.GetString() : "";
        var commitTitle = push.TryGetProperty("commit_title", out var ct) ? ct.GetString() : "";
        var commitCount = push.TryGetProperty("commit_count", out var cc) ? cc.GetInt32() : 0;
        Console.WriteLine($"{created} | {action} | {targetTitle} | branch:{refName} | {commitTitle} ({commitCount} commits)");
    }
    else
    {
        Console.WriteLine($"{created} | {action} | {targetType} | {targetTitle}");
    }
}
