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

  # Guard: skip if link_path and target_path resolve to the same file
  # (e.g. ~/.config is already a symlink to $DOTDIR/.config)
  local resolved_link resolved_target
  resolved_link="$(readlink -f "$(dirname "$link_path")")/$(basename "$link_path")"
  resolved_target="$(readlink -f "$target_path")"
  if [ "$resolved_link" = "$resolved_target" ]; then
    echo "Skipping (same path): $link_path"
    return
  fi

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
make_symlink "$HOME/.bunfig.toml"          "$DOTDIR/.bunfig.toml"
make_symlink "$HOME/.aws/config"          "$DOTDIR/.aws/config"
make_symlink "$HOME/.config/starship.toml" "$DOTDIR/.config/starship.toml"
make_symlink "$HOME/.config/lazygit"      "$DOTDIR/.config/lazygit"
make_symlink "$HOME/.config/mise"         "$DOTDIR/.config/mise"
make_symlink "$HOME/.config/nvim"         "$DOTDIR/.config/nvim"
make_symlink "$HOME/.config/nushell"      "$DOTDIR/.config/nushell"
make_symlink "$HOME/.config/gcloud/configurations" "$DOTDIR/.config/gcloud/configurations"
make_symlink "$HOME/.config/herdr/config.toml" "$DOTDIR/.config/herdr/config.toml"
make_symlink "$HOME/.bin"                 "$DOTDIR/.bin"
make_symlink "$HOME/.sound"              "$DOTDIR/sound"

# 2. Claude Code settings
print_step "Linking Claude Code settings..."
command mkdir -p "$HOME/.claude"
make_symlink "$HOME/.claude/CLAUDE.md"     "$DOTDIR/.config/claude-code/CLAUDE.md"
make_symlink "$HOME/.claude/settings.json" "$DOTDIR/.config/claude-code/settings.json"
make_symlink "$HOME/.claude/rules"         "$DOTDIR/.config/claude-code/rules"
make_symlink "$HOME/.claude/skills"        "$DOTDIR/.config/claude-code/skills"
make_symlink "$HOME/.claude/hooks"         "$DOTDIR/.config/claude-code/hooks"

# External skills (symlinks to ghq-managed repos, not tracked in dotfiles)
YAML_TO_HTML_SKILL="$HOME/ghq/github.com/hirokita117/yaml-to-html-skill/skills"
if [ -d "$YAML_TO_HTML_SKILL" ]; then
  make_symlink "$DOTDIR/.config/claude-code/skills/generate-explainer"      "$YAML_TO_HTML_SKILL/generate-explainer"
  make_symlink "$DOTDIR/.config/claude-code/skills/generate-explainer-html" "$YAML_TO_HTML_SKILL/generate-explainer-html"
  make_symlink "$DOTDIR/.config/claude-code/skills/generate-explainer-yaml" "$YAML_TO_HTML_SKILL/generate-explainer-yaml"
else
  echo "  Skipping yaml-to-html-skill links (repo not found at $YAML_TO_HTML_SKILL)"
fi

# 3. WSL2: route xdg-open to the default Windows browser
if [ -x /mnt/c/Windows/System32/cmd.exe ] && command -v xdg-settings > /dev/null 2>&1; then
  print_step "Installing wsl-browser.desktop..."
  command mkdir -p "$HOME/.local/share/applications"
  command rm -f "$HOME/.local/share/applications/wsl-browser.desktop"
  cat > "$HOME/.local/share/applications/wsl-browser.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=WSL Browser
Comment=Open URL in the default Windows browser from WSL2
Exec=$HOME/.bin/wsl-browser %u
NoDisplay=true
MimeType=x-scheme-handler/http;x-scheme-handler/https;x-scheme-handler/about;x-scheme-handler/unknown;text/html;
EOF
  xdg-settings set default-web-browser wsl-browser.desktop
  if command -v xdg-mime > /dev/null 2>&1; then
    xdg-mime default wsl-browser.desktop \
      text/html \
      x-scheme-handler/about \
      x-scheme-handler/unknown
  fi
  print_step "  default-web-browser -> $(xdg-settings get default-web-browser)"
fi

# 4. Git config
# credential.helper は OS ごとに実体が異なるため ~/.gitconfig.local に切り出す。
# ~/.gitconfig_shared と ~/.gitconfig.local の include は .gitconfig 側で宣言済み。
print_step "Configuring git..."
GCM_PATH="/mnt/c/Program Files/Git/mingw64/bin/git-credential-manager.exe"
if [ -x "$GCM_PATH" ]; then
  credential_helper="\"$GCM_PATH\""
  echo "  credential.helper: Git Credential Manager (WSL2)"
elif [ -x /usr/libexec/git-core/git-credential-libsecret ] \
  || [ -x /usr/lib/git-core/git-credential-libsecret ]; then
  credential_helper="libsecret"
  echo "  credential.helper: libsecret (GNOME keyring)"
else
  credential_helper="cache --timeout=21600"
  echo "  credential.helper: cache (6h)  # libsecret 導入で永続化できる"
fi
cat > "$HOME/.gitconfig.local" <<EOF
# このファイルは .bin/install.sh が生成する。手で編集しても再実行で上書きされる。
[credential]
	helper = $credential_helper
EOF
print_step "  $HOME/.gitconfig.local -> credential.helper = $credential_helper"

# 5. apt sources.list.d symlink + PGP keys (requires sudo)
# リポジトリ内の apt sources は特定 Ubuntu リリース固定。実行中のリリースと食い違う場合、
# /etc/apt/sources.list.d を symlink すると ubuntu.sources ごと別リリースに差し替わり、
# ディストリビューション全体のダウングレードを招くため、apt 設定は丸ごと中止する。
repo_suite="$(awk '/^Suites:/ {print $2; exit}' "$DOTDIR/etc/apt/sources.list.d/ubuntu.sources" 2>/dev/null || true)"
host_suite="$( . /etc/os-release 2>/dev/null; echo "${UBUNTU_CODENAME:-}" )"
if [ -n "$repo_suite" ] && [ -n "$host_suite" ] && [ "$repo_suite" != "$host_suite" ]; then
  print_step "Skipping apt configuration (release mismatch)."
  echo "  repo の apt sources は '$repo_suite' 固定だが、実行中の Ubuntu は '$host_suite'。"
  echo "  適用するとシステムが '$repo_suite' にダウングレードされるため中止する。"
  echo "  '$host_suite' 用のリポジトリ設定は手動で行うこと。"
elif command -v apt-get > /dev/null 2>&1; then
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

# 6. apt package restore (requires dselect)
if command -v dselect > /dev/null 2>&1 && [ "${repo_suite:-}" = "${host_suite:-}" ]; then
  pkg_list="$DOTDIR/.bin/apt-installed.list"
  if [ -f "$pkg_list" ]; then
    print_step "Restoring apt packages from apt-installed.list..."
    read -r -p "Proceed with package restore? [y/N] " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
      sudo dpkg --set-selections < "$pkg_list"
      sudo apt-get dselect-upgrade -y
    else
      echo "Skipping package restore."
    fi
  fi
fi

# 7. tmux plugin manager
print_step "Setting up tmux plugin manager..."
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
  echo "  tpm already installed, skipping."
else
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# 8. Done
print_step ""
print_step " Install completed!!!! "
