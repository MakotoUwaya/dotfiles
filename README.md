# dotfiles

## Using

### Install

- [jdx/mise](https://github.com/jdx/mise)
    - The front-end to your dev env
- [x-motemen/ghq](https://github.com/x-motemen/ghq)

```sh
mise use -g ghq
```

```sh
ghq clone https://github.com/MakotoUwaya/dotfiles.git
```

### For WSL2 Ubuntu

#### Setup WSL2

How to install Linux on Windows with WSL  
https://learn.microsoft.com/ja-jp/windows/wsl/install

```sh
wsl --install -d Ubuntu-24.04
```

#### Initialize

```sh
sudo apt update && \
sudo apt upgrade -y && \
sudo apt autoremove -y && \
sudo apt install dselect && \
sudo dselect update
```

#### Clone dotfiles

install mise & ghq
clone dotfiles

#### Install Node.js

```sh
cd ~/ghq/github.com/MakotoUwaya/dotfiles/
mise use -g node@24
```

#### Install Rust

```sh
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

#### Run install script

シンボリックリンク作成、apt sources/PGP 鍵設定、パッケージ復元を一括で実行:

```sh
~/ghq/github.com/MakotoUwaya/dotfiles/.bin/install.sh
```

デバッグモード（詳細出力）:

```sh
~/ghq/github.com/MakotoUwaya/dotfiles/.bin/install.sh --debug
```

### For Windows

管理者権限の PowerShell で以下を実行:

```powershell
~\ghq\github.com\MakotoUwaya\dotfiles\.bin\install.ps1
```

デバッグモード（詳細出力）:

```powershell
~\ghq\github.com\MakotoUwaya\dotfiles\.bin\install.ps1 -Debug
```

## ノート

### WSL2 から Windows ブラウザを開く仕組み

WSL2 上で `xdg-open` や `gh repo view --web`, `cargo doc --open` 等を実行した際に、Windows 側の既定ブラウザが開くように構成している。

**呼び出し経路**:
`xdg-open <URL>` → `~/.local/share/applications/wsl-browser.desktop` → `~/.bin/wsl-browser` → `rundll32.exe url.dll,FileProtocolHandler <URL>` → Windows 既定ブラウザ

**関連ファイル**:

- `.bin/wsl-browser`: URL を受け取って `rundll32.exe` に渡すだけの薄い bash ラッパ。`cmd.exe /c start` を避ける理由は、クエリ文字列中の `&` が `cmd.exe` のコマンド区切りとして解釈されて URL が壊れるため。`rundll32` は `cmd.exe` を経由しないので `&`・日本語・スペースを含む URL も安全に渡る。加えて UNC パス (`\\wsl.localhost\...`) を CWD としたときに `cmd.exe` が出す警告も回避できる。
- `.bin/install.sh`: WSL2 判定（`/mnt/c/Windows/System32/cmd.exe` の実行可否）下で `~/.local/share/applications/wsl-browser.desktop` を heredoc で生成し、`xdg-settings set default-web-browser` と `xdg-mime default` で既定ハンドラに登録する。Desktop Entry の `Exec=` には `$HOME/.bin/wsl-browser` 展開済みの絶対パスを書き出すため、生成物は dotfiles リポジトリには含めず install 時にユーザーごとに生成する方針（`$HOME` や `~` は Desktop Entry 仕様で展開されない）。

**依存パッケージ**（`.bin/apt-installed.list` に含まれる）:

- `xdg-utils`（`xdg-open`, `xdg-settings`, `xdg-mime` を提供）
- `desktop-file-utils`（`desktop-file-validate` による検証用）

**確認コマンド**:

```sh
xdg-settings get default-web-browser         # -> wsl-browser.desktop
xdg-open "https://example.com/?q=1&a=2"      # クエリ付き URL も壊れず Windows で開く
```

**参考**: [WSL2の中からWindows側のブラウザを開く](https://diary.shu-cream.net/WSL2%E3%81%AE%E4%B8%AD%E3%81%8B%E3%82%89Windows%E5%81%B4%E3%81%AE%E3%83%96%E3%83%A9%E3%82%A6%E3%82%B6%E3%82%92%E9%96%8B%E3%81%8F)

