using System.Text.Json;

var input = args.Length > 0
    ? File.ReadAllText(args[0])
    : Console.In.ReadToEnd();

var events = JsonDocument.Parse(input).RootElement;

foreach (var e in events.EnumerateArray())
{
    var created = e.GetProperty("created_at").GetString()?[..19] ?? "";
    var action = e.GetProperty("action_name").GetString() ?? "";
    var targetType = e.GetProperty("target_type").GetString() ?? "";
    var targetTitle = e.GetProperty("target_title").GetString() ?? "";
    var targetIid = e.TryGetProperty("target_iid", out var iid) ? iid.ToString() : "";

    var refName = "";
    var commitCount = 0;
    var commitTitle = "";
    if (e.TryGetProperty("push_data", out var pd) && pd.ValueKind == JsonValueKind.Object)
    {
        refName = pd.TryGetProperty("ref", out var r) && r.ValueKind == JsonValueKind.String ? r.GetString() ?? "" : "";
        commitCount = pd.TryGetProperty("commit_count", out var cc) ? cc.GetInt32() : 0;
        commitTitle = pd.TryGetProperty("commit_title", out var ct) && ct.ValueKind == JsonValueKind.String ? ct.GetString() ?? "" : "";
    }

    var noteType = "";
    if (e.TryGetProperty("note", out var n) && n.ValueKind == JsonValueKind.Object)
    {
        noteType = n.TryGetProperty("noteable_type", out var nt) ? nt.GetString() ?? "" : "";
    }

    Console.WriteLine($"{created} | {action} | {targetType} | {targetTitle} | iid:{targetIid} | ref:{refName} cc:{commitCount} ct:{commitTitle} | note:{noteType}");
}
