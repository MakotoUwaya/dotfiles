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

