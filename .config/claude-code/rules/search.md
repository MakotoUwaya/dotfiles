## 検索コマンド実行ルール

Bash での検索は `rg`（ripgrep）を使う（`grep`/`ag`/`find`/`fd` は使わない）。
テキスト検索: `rg "pattern"`、ファイル検索: `rg --files -g "*.ts"`。
組み込みツール（Glob, Grep, Read）が使える場面ではそちらを優先。
