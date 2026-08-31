# env.nu
#
# 環境変数・PATH・ツール activation スクリプト生成

# === 環境変数 ===
$env.EDITOR = "nvim"
$env.COLORTERM = "truecolor"
$env.RIPGREP_CONFIG_PATH = ($env.HOME | path join ".ripgreprc")

# fzf
$env.FZF_DEFAULT_OPTS = "--prompt='QUERY> ' --height 60% --layout reverse --border=rounded --style full"
$env.FZF_CTRL_T_COMMAND = ""
$env.FZF_ALT_C_OPTS = "--height 100% --preview 'eza {} -h -T -F --no-user --no-time --no-filesize --no-permissions --long | head -200'"

# everything-claude-code: hook 厳密度（minimal | standard | strict）
$env.ECC_HOOK_PROFILE = "minimal"

# PATH 追加
$env.PATH = ($env.PATH | prepend ($env.HOME | path join "go" "bin"))
$env.PATH = ($env.PATH | prepend ($env.HOME | path join ".local" "bin"))
$env.PATH = ($env.PATH | prepend ($env.HOME | path join "bin"))

# OS 別設定（WSL）
if $nu.os-info.name == "linux" {
    $env.GPG_TTY = (^tty)
    $env.PNPM_HOME = ($env.HOME | path join ".local" "share" "pnpm")
    $env.PATH = ($env.PATH | prepend $env.PNPM_HOME)
    $env.CLAUDE_CODE_SKIP_WINDOWS_PROFILE = "1"
}

# starship / mise の activation スクリプトを vendor/autoload に生成（自動読込）
let autoload_dir = ($nu.default-config-dir | path join "vendor" "autoload")
mkdir $autoload_dir
^starship init nu | save -f ($autoload_dir | path join "starship.nu")
^mise activate nu | save -f ($autoload_dir | path join "mise.nu")
