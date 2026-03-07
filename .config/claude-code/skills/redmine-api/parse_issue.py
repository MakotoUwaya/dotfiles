"""Redmine MCP getIssue のレスポンスファイルをパースして表示する。

Usage:
    python parse_issue.py <saved_file_path> [--journals]
"""

import json
import sys


def parse_issue_file(file_path: str) -> dict:
    """MCP レスポンスファイルから issue dict を取得する。

    構造: [{type: "text", text: "<JSON string>"}]
    text の中身: {"data": {"issue": { ... }}}
    """
    with open(file_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    inner = json.loads(data[0]["text"])
    return inner["data"]["issue"]


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <file_path> [--journals]", file=sys.stderr)
        sys.exit(1)

    file_path = sys.argv[1]
    show_journals = "--journals" in sys.argv

    issue = parse_issue_file(file_path)

    print(f"Subject: {issue['subject']}")
    print(f"Status: {issue['status']['name']}")
    print(f"Tracker: {issue['tracker']['name']}")
    print(f"Author: {issue['author']['name']}")
    print()
    print("=== Description ===")
    print(issue.get("description", "(empty)"))

    if show_journals:
        journals = issue.get("journals", [])
        print(f"\n=== Journals ({len(journals)} total) ===")
        for j in journals:
            notes = j.get("notes", "")
            if notes.strip():
                user = j.get("user", {}).get("name", "?")
                created = j.get("created_on", "?")
                print(f"\n--- {user} ({created}) ---")
                print(notes)


if __name__ == "__main__":
    main()
