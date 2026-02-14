#!/usr/bin/env bash
set -ue

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTDIR="$(dirname "$SCRIPT_DIR")"
BACKUP_DIR="$HOME/.dotbackup"

# --- Helper functions (corresponding to install.ps1) ---

print_step() {
  command echo -e "\e[1;36m$1\e[m"
}

ensure_backup_dir() {
  if [ ! -d "$BACKUP_DIR" ]; then
    echo "$BACKUP_DIR not found. Auto Make it"
    command mkdir -p "$BACKUP_DIR"
  fi
}

backup_item() {
  local path="$1"
  ensure_backup_dir
  local name
  name="$(basename "$path")"
  local dest="$BACKUP_DIR/$name"
  if [ -e "$dest" ]; then
    command rm -rf "$dest"
  fi
  command mv "$path" "$BACKUP_DIR/"
  echo "Backed up: $path -> $BACKUP_DIR"
}

make_symlink() {
  local link_path="$1"
  local target_path="$2"

  local parent_dir
  parent_dir="$(dirname "$link_path")"
  if [ ! -d "$parent_dir" ]; then
    echo "Creating parent directory: $parent_dir"
    command mkdir -p "$parent_dir"
  fi

  if [ -e "$link_path" ] || [ -L "$link_path" ]; then
    if [ -L "$link_path" ]; then
      echo "Removing existing symlink: $link_path"
      command rm -f "$link_path"
    else
      echo "Backing up existing item: $link_path"
      backup_item "$link_path"
    fi
  fi

  command ln -snf "$target_path" "$link_path"
  print_step "  $link_path -> $target_path"
}

helpmsg() {
  command echo "Usage: $0 [--help | -h] [--debug | -d]" 0>&2
  command echo ""
}

# --- Parse arguments ---
while [ $# -gt 0 ]; do
  case ${1} in
    --debug|-d)
      set -uex
      ;;
    --help|-h)
      helpmsg
      exit 1
      ;;
    *)
      ;;
  esac
  shift
done

# --- Main ---
print_step "Starting Linux/WSL dotfiles installation..."
print_step "Dotfiles directory: $DOTDIR"

# 1. Symlinks
print_step "Creating symlinks..."
make_symlink "$HOME/.bashrc"              "$DOTDIR/.bashrc"
make_symlink "$HOME/.bash_aliases"        "$DOTDIR/.bash_aliases"
make_symlink "$HOME/.bash_logout"         "$DOTDIR/.bash_logout"
make_symlink "$HOME/.profile"             "$DOTDIR/.profile"
make_symlink "$HOME/.gitconfig"           "$DOTDIR/.gitconfig"
make_symlink "$HOME/.ripgreprc"           "$DOTDIR/.ripgreprc"
make_symlink "$HOME/.tmux.conf"           "$DOTDIR/.tmux.conf"
make_symlink "$HOME/.config/starship.toml" "$DOTDIR/.config/starship.toml"
make_symlink "$HOME/.config/lazygit"      "$DOTDIR/.config/lazygit"
make_symlink "$HOME/.config/mise"         "$DOTDIR/.config/mise"
make_symlink "$HOME/.config/nvim"         "$DOTDIR/.config/nvim"
make_symlink "$HOME/.bin"                 "$DOTDIR/.bin"

# 2. Claude Code settings
print_step "Linking Claude Code settings..."
command mkdir -p "$HOME/.claude"
make_symlink "$HOME/.claude/settings.json" "$DOTDIR/.config/claude-code/settings.json"
make_symlink "$HOME/.claude/rules"         "$DOTDIR/.config/claude-code/rules"
make_symlink "$HOME/.claude/skills"        "$DOTDIR/.config/claude-code/skills"

# 3. Git config
print_step "Configuring git..."
git config --global include.path "~/.gitconfig_shared"

# 4. apt sources.list.d symlink + PGP keys (requires sudo)
if command -v apt-get > /dev/null 2>&1; then
  print_step "Setting up apt sources and PGP keys..."
  echo "This step requires sudo privileges."
  read -r -p "Proceed with apt configuration? [y/N] " response
  if [[ "$response" =~ ^[Yy]$ ]]; then
    # sources.list.d symlink
    if [ -d /etc/apt/sources.list.d ] && [ ! -L /etc/apt/sources.list.d ]; then
      sudo mv /etc/apt/sources.list.d /etc/apt/backup-sources.list.d
      sudo ln -snf "$DOTDIR/etc/apt/sources.list.d" /etc/apt/sources.list.d
      sudo rm -rf /etc/apt/backup-sources.list.d
      print_step "  /etc/apt/sources.list.d -> $DOTDIR/etc/apt/sources.list.d"
    elif [ -L /etc/apt/sources.list.d ]; then
      echo "  /etc/apt/sources.list.d is already a symlink, skipping."
    fi

    # PGP keys
    sudo mkdir -p /usr/share/keyrings /etc/apt/keyrings /etc/apt/trusted.gpg.d
    sudo cp "$DOTDIR/usr/share/keyrings/cloud.google.gpg"              /usr/share/keyrings/
    sudo cp "$DOTDIR/usr/share/keyrings/docker-archive-keyring.gpg"    /usr/share/keyrings/
    sudo cp "$DOTDIR/usr/share/keyrings/hashicorp-archive-keyring.gpg" /usr/share/keyrings/
    sudo cp "$DOTDIR/etc/apt/keyrings/mise-archive-keyring.pub"        /etc/apt/keyrings/
    sudo cp "$DOTDIR/etc/apt/trusted.gpg.d/google-chrome.gpg"         /etc/apt/trusted.gpg.d/
    print_step "  PGP keys copied."

    # apt update
    print_step "Running apt update..."
    sudo apt-get update
  else
    echo "Skipping apt configuration."
  fi
fi

# 5. apt package restore (requires dselect)
if command -v dselect > /dev/null 2>&1; then
  local_list="$DOTDIR/.bin/apt-installed.list"
  if [ -f "$local_list" ]; then
    print_step "Restoring apt packages from apt-installed.list..."
    read -r -p "Proceed with package restore? [y/N] " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
      sudo dpkg --set-selections < "$local_list"
      sudo apt-get dselect-upgrade -y
    else
      echo "Skipping package restore."
    fi
  fi
fi

# 6. tmux plugin manager
print_step "Setting up tmux plugin manager..."
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
  echo "  tpm already installed, skipping."
else
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# 7. Done
print_step ""
print_step " Install completed!!!! "
