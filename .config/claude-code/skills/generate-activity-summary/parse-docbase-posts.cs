using System.Text.Json;

var json = Console.In.ReadToEnd();
var root = JsonDocument.Parse(json).RootElement;

// DocBase MCP returns [{type, text}] where text contains the JSON response
JsonElement posts;
if (root.ValueKind == JsonValueKind.Array
    && root.GetArrayLength() > 0
    && root[0].TryGetProperty("text", out var textEl))
{
    var inner = JsonDocument.Parse(textEl.GetString()!).RootElement;
    posts = inner.GetProperty("posts");
}
else if (root.TryGetProperty("posts", out var p))
{
    posts = p;
}
else
{
    return;
}

foreach (var post in posts.EnumerateArray())
{
    var title = post.GetProperty("title").GetString() ?? "";
    var created = post.GetProperty("created_at").GetString() ?? "";
    var changed = post.TryGetProperty("changed_at", out var ch) ? ch.GetString() ?? "" : "";
    Console.WriteLine($"title: {title} | created: {created} | changed: {changed}");
}
