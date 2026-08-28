# config.nu
#
# エイリアス・カスタムコマンド・キーバインド設定

# === General ===
$env.config.show_banner = false

# === History ===
$env.config.history = {
    max_size: 2000
    sync_on_enter: true
    file_format: "sqlite"
    isolation: false
}

# === Aliases ===
alias ll = ls -la
alias la = ls -a
alias gg = lazygit
alias vim = nvim
alias globalip = curl httpbin.org/ip

# === Custom Commands ===

# ghq リポジトリ選択 (Ctrl+G)
def --env gitdir [] {
    let selected = (^ghq list --full-path | ^fzf -e | str trim)
    if ($selected | is-not-empty) {
        cd $selected
    }
}

# ripgrep + fzf でファイル内検索 → nvim で開く (Ctrl+F)
def rgfzf [] {
    let result = (^rg --column --line-number --no-heading --color=always --smart-case --hidden . | ^fzf --ansi --delimiter : --height 100% --layout reverse --border rounded | str trim)
    if ($result | is-not-empty) {
        let parts = ($result | split row ":")
        let file = $parts.0
        let line = $parts.1
        ^nvim $file $"+($line)"
    }
}

# fzf でディレクトリ移動 (Alt+C)
def --env fzf-cd [] {
    let dir = (^fd --type d --color=never | ^fzf --height 100% --preview "eza {} -h -T -F --no-user --no-time --no-filesize --no-permissions --long | head -200" | str trim)
    if ($dir | is-not-empty) {
        cd $dir
    }
}

# fzf でファイル選択 → nvim で開く
def sef [] {
    let file = (^fd --type f --strip-cwd-prefix | ^fzf --height 100% -e | str trim)
    if ($file | is-not-empty) {
        ^nvim $file
    }
}

# === Keybindings ===
$env.config.keybindings = ($env.config.keybindings | append [
    {
        name: ghq_selector
        modifier: control
        keycode: char_g
        mode: [emacs vi_normal vi_insert]
        event: { send: ExecuteHostCommand, cmd: "gitdir" }
    }
    {
        name: rg_fzf_search
        modifier: control
        keycode: char_f
        mode: [emacs vi_normal vi_insert]
        event: { send: ExecuteHostCommand, cmd: "rgfzf" }
    }
    {
        name: fzf_directory
        modifier: alt
        keycode: char_c
        mode: [emacs vi_normal vi_insert]
        event: { send: ExecuteHostCommand, cmd: "fzf-cd" }
    }
])
