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
cd ghq/github.com/MakotoUwaya/dotfiles/
mise use -g node@24
```

#### Install apt

```sh
sudo mv /etc/apt/sources.list.d/ /etc/apt/backup-sources.list.d/
sudo ln -s /home/makot/ghq/github.com/MakotoUwaya/dotfiles/etc/apt/sources.list.d /etc/apt/sources.list.d
sudo rm -r /etc/apt/backup-sources.list.d/
ll /etc/apt/
```

```sh
sudo cp ./usr/share/keyrings/cloud.google.gpg /usr/share/keyrings/ \
sudo cp ./usr/share/keyrings/docker-archive-keyring.gpg /usr/share/keyrings/ \
sudo cp ./usr/share/keyrings/hashicorp-archive-keyring.gpg /usr/share/keyrings/ \
sudo cp ./etc/apt/keyrings/mise-archive-keyring.pub /etc/apt/keyrings/ \
sudo cp ./etc/apt/trusted.gpg.d/google-chrome.gpg /etc/apt/trusted.gpg.d/
```

```sh
sudo apt update && sudo dselect update
sudo apt update && sudo dselect update && sudo apt upgrade -y
```

```sh
sudo dpkg --set-selections < ~/ghq/github.com/MakotoUwaya/dotfiles/.bin/apt-installed.list
sudo apt-get dselect-upgrade -y
```

#### Install Rust

```sh
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

```sh
~/ghq/github.com/MakotoUwaya/dotfiles/.bin/install.sh
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

