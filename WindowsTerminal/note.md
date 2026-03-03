# Windows Terminal settings.json の管理方針

## 概要

`settings.json` はシンボリックリンクではなく **コピー配置** で管理する。
Terminal はプロファイル自動検出の結果を `settings.json` に書き戻すため、シンボリックリンクだと dotfiles リポジトリが汚れる問題がある。

## 既にシンボリックリンク化されている場合の復元手順

PowerShell を **管理者権限** で開き、以下を実行する。

### 1. 現在の状態を確認

```powershell
$wtSettings = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
(Get-Item $wtSettings -Force).Attributes
```

出力に `ReparsePoint` が含まれていればシンボリックリンク。

### 2. シンボリックリンクを削除

```powershell
(Get-Item $wtSettings -Force).Delete()
```

> `Remove-Item` ではなく `.Delete()` を使う。`Remove-Item` はリンク先のファイルを削除してしまう場合がある。

### 3. テンプレートをコピー配置

```powershell
$dotdir = "$HOME\ghq\github.com\MakotoUwaya\dotfiles"  # 環境に合わせて変更
Copy-Item -Path (Join-Path $dotdir 'WindowsTerminal\settings.json') -Destination $wtSettings
```

### 4. Windows Terminal を起動して確認

- Terminal を起動すると、WSL ディストリビューション等のプロファイルが自動検出され `profiles.list` に追加される
- `profiles.defaults` のフォント・透過設定が全プロファイルに適用されていることを確認する
- dotfiles リポジトリ側の `git status` が clean のままであることを確認する
