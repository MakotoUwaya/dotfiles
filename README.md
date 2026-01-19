# dotfiles

## Using

```sh
ghq clone https://github.com/MakotoUwaya/dotfiles.git
```

### For Ubuntu

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
winget import "$env:USERPROFILE\ghq\github.com\MakotoUwaya\dotfiles\winget\settings.json"
```

