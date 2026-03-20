using System.Text.Json;

var input = args.Length > 0
	? File.ReadAllText(args[0])
	: Console.In.ReadToEnd();

var array = JsonDocument.Parse(input).RootElement;
var issueJson = array[0].GetProperty("text").GetString()!;
var inner = JsonDocument.Parse(issueJson).RootElement;
var issue = inner.TryGetProperty("data", out var data)
	? data.GetProperty("issue")
	: inner.GetProperty("issue");

Console.WriteLine($"Subject: {issue.GetProperty("subject").GetString()}");
Console.WriteLine($"Status: {issue.GetProperty("status").GetProperty("name").GetString()}");
Console.WriteLine($"Tracker: {issue.GetProperty("tracker").GetProperty("name").GetString()}");

if (issue.TryGetProperty("assigned_to", out var assignee))
	Console.WriteLine($"Assigned to: {assignee.GetProperty("name").GetString()}");

var desc = issue.GetProperty("description").GetString() ?? "";
if (desc.Length > 3000) desc = desc[..3000] + "\n... (truncated)";
Console.WriteLine($"\n--- Description ---\n{desc}");

if (issue.TryGetProperty("journals", out var journals))
{
	Console.WriteLine("\n--- Journals (with notes) ---");
	foreach (var j in journals.EnumerateArray())
	{
		var notes = j.GetProperty("notes").GetString();
		if (string.IsNullOrWhiteSpace(notes)) continue;

		var user = j.GetProperty("user").GetProperty("name").GetString();
		var id = j.GetProperty("id").GetRawText();
		var created = j.GetProperty("created_on").GetString();
		Console.WriteLine($"\n[#{id}] {user} ({created}):");
		if (notes.Length > 1000) notes = notes[..1000] + "\n... (truncated)";
		Console.WriteLine(notes);
	}
}
