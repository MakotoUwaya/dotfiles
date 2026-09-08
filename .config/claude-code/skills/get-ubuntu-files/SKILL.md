---
name: get-ubuntu-files
description: ssh 接続先の Ubuntu 機からファイルを取得し、Windows 機の Downloads フォルダに配置する。日本語ファイル名・1 文字ホスト名・ControlMaster 非対応といった Windows 固有の落とし穴を回避した手順を提供する。「Ubuntu からファイル取って」「リモートのファイルを Downloads に」「ssh m のファイルを取得」で使用。
---

# Get Ubuntu Files

## Overview

`ssh` で接続できる Ubuntu 機（既定は `~/.ssh/config` のホスト `m`）から
ファイルを 1 つ取得し、Windows 機の `~\Downloads` に配置する。

Windows ネイティブの Claude Code セッションでは、素直な `scp` や
Git Bash 経由の `ssh` が**いずれも失敗する**。
このスキルは実際に通った手順とその根拠を固定する。

## When to Use

- 「Ubuntu からファイル取って」「リモートのファイルを Downloads に」と指示されたとき
- `ssh m` で入れる機体上のファイル（Excel、ログ、成果物など）を手元で開きたいとき

**適用条件**: Windows ネイティブの Claude Code セッション。
WSL2 セッション内から WSL2 のファイルシステムに置く場合は対象外（通常の `scp` で足りる）。

## Instructions

### 1. リモートのファイルを確認する

パスが正しいか、サイズがどれくらいかを先に確認する。

```powershell
ssh -o ClearAllForwardings=yes -o ControlMaster=no -o ControlPath=none -o ConnectTimeout=10 m 'ls -l "<リモート絶対パス>"'
```

パスがうろ覚えの場合はディレクトリを列挙して特定する。

```powershell
ssh -o ClearAllForwardings=yes -o ControlMaster=no -o ControlPath=none m 'ls -l "<ディレクトリ>"'
```

### 2. Downloads の同名ファイルを確認する

上書き事故を避けるため、取得前に必ず確認する。

```powershell
Get-ChildItem "$HOME\Downloads\<ファイル名>" -ErrorAction SilentlyContinue | Select-Object Name, Length, LastWriteTime
```

同名ファイルがあれば、上書きしてよいかユーザーに確認する。

### 3. 転送する

```powershell
scp -o ClearAllForwardings=yes -o ControlMaster=no -o ControlPath=none "scp://m/<リモート絶対パス>" "$HOME\Downloads\"
```

`scp://m/` の直後にリモートパスの先頭 `/` が続くため、
結果として `scp://m//home/...` とスラッシュが 2 つ並ぶ。これは正しい。

**1 行で書くこと。** PowerShell のバッククォート行継続（`` ` ``）は
Claude Code の PowerShell ツール経由では使わない。

### 4. 検証して報告する

サイズがリモートと一致することを必ず確認する。

```powershell
$p = "$HOME\Downloads\<ファイル名>"
Get-Item $p | Select-Object Name, Length, LastWriteTime | Format-List
```

Office ファイル（.xlsx / .docx / .pptx）の場合は zip マジックも確認する。

```powershell
"magic: " + (([byte[]](Get-Content $p -AsByteStream -TotalCount 4)) | ForEach-Object { $_.ToString('X2') }) -join ' '
```

`50 4B 03 04`（= `PK\x03\x04`）であれば正常。

報告には**配置先の絶対パス**と**サイズがリモートと一致したこと**を含める。

## Examples

### 日本語ファイル名の Excel を取得する

```powershell
scp -o ClearAllForwardings=yes -o ControlMaster=no -o ControlPath=none "scp://m//home/m-uwaya/ghq/gitlab.com/eseikatsu/ebone-api/ebone-cli/CQ物件台帳（R3版・消毒改定版）.xlsx" "$HOME\Downloads\"
```

報告:

> **配置先**: `C:\Users\100508\Downloads\CQ物件台帳（R3版・消毒改定版）.xlsx`
>
> **検証結果**
> - サイズ: 15,643,241 バイト（リモートと一致）
> - 先頭バイト: `50 4B 03 04` = `PK\x03\x04`（xlsx = zip として正常）

## Guidelines

### 4 つのオプションはすべて必須（省略すると失敗する）

| 指定 | 理由 | 省略時のエラー |
|---|---|---|
| PowerShell の `ssh.exe` を使う | 秘密鍵の passphrase が Windows の `ssh-agent` サービス側で解決される。Git Bash の `/usr/bin/ssh` はこのサービスと通信できず（`SSH_AUTH_SOCK` 未設定）、非対話シェルでは passphrase 待ちでハングする | 無反応のままタイムアウト |
| `-o ControlMaster=no -o ControlPath=none` | `~/.ssh/config` に `ControlMaster auto` があるが、ネイティブ `ssh.exe` は接続多重化に非対応 | `getsockname failed: Not a socket` / `Read from remote host: Unknown error` |
| `-o ClearAllForwardings=yes` | `~/.ssh/config` の `LocalForward` が既存セッションとポート衝突する | `bind [127.0.0.1]:NNNN: Address already in use` → `Could not request local forwarding` |
| `scp://m/<絶対パス>` 形式 | ホスト名 `m` が 1 文字なので、`m:` 形式だと Windows の `scp` がドライブレターと誤認する。また `scp://` URI で絶対パスを表すにはスラッシュが 2 つ必要 | `The system cannot find the drive specified` / `No such file or directory`（先頭 `/` が落ちて相対パス扱い） |

### その他

- ホスト名は既定 `m`。別ホストを指定された場合は `m` を差し替える。
  1 文字でないホスト名でも `scp://` 形式のままで動くので、形式は変えない
- 日本語・全角括弧・`・` を含むパスは、PowerShell のダブルクォートで囲めばそのまま通る。
  リモート側で `ls` する際は `'...'` の中で `"..."` と二重に囲む
- `Warning: No xauth data; using fake authentication data for X11 forwarding.` は
  X11 転送設定に由来する無害な警告。転送は成功しているので報告に含めない
- バイナリを PowerShell の `>` でリダイレクトしないこと。
  テキストとしてエンコードされ、ファイルが破損する。必ず `scp` を使う

### 現在の制約

**複数パスの同時指定は未対応**（1 回の実行で 1 ファイル）。
複数ファイルを頼まれた場合は、手順 1〜4 をファイルごとに繰り返す。
将来的に複数パス対応を追加する予定。
