# dotfiles

## Using

### Install

- [jdx/mise](https://github.com/jdx/mise)
    - The front-end to your dev env
- [x-motemen/ghq](https://github.com/x-motemen/ghq)

```sh
mise install ghq && mise use ghq
```

```sh
ghq clone https://github.com/MakotoUwaya/dotfiles.git
```

### For Ubuntu

```sh
sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
```

```sh
~/ghq/github.com/MakotoUwaya/dotfiles/.bin/install.sh
```

### For Windows

```sh
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\Documents\PowerShell\" -Target "$env:USERPROFILE\ghq\github.com\MakotoUwaya\dotfiles\PowerShell\"
```

```sh
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\AppData\Local\nvim\" -Target "$env:USERPROFILE\ghq\github.com\MakotoUwaya\dotfiles\.config\nvim\"
```

```sh
New-Item -ItemType SymbolicLink -Path "$HOME\.config\mise\" -Target "$env:USERPROFILE\ghq\github.com\MakotoUwaya\dotfiles\.config\mise\"
```

```sh
New-Item -ItemType SymbolicLink -Path "$HOME\.ripgreprc" -Target "$env:USERPROFILE\ghq\github.com\MakotoUwaya\dotfiles\.ripgreprc"
```

```sh
winget import "$env:USERPROFILE\ghq\github.com\MakotoUwaya\dotfiles\winget\settings.json"
```

