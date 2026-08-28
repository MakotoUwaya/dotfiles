# Utility aliases
alias globalip='curl httpbin.org/ip'
# クリップボード / ファイラ。WSL2 は Windows 側、ネイティブ Linux は X/Wayland 側に振り分ける。
if [ -d /mnt/c/Windows ]; then
  alias clip='iconv -t utf16 | /mnt/c/Windows/System32/clip.exe'
  alias explorer='/mnt/c/Windows/explorer.exe'
else
  alias clip='xclip -selection clipboard'
  explorer() { xdg-open "${1:-.}"; }
fi
alias gg=lazygit
alias dbproxy-tui='bun run ~/.bin/dbproxy-tui/index.ts'

# Voice alert alias for long running commands
alias beep='aplay -q -D pulse ~/.sound/voice_終わりました_ロザリア・ガーネット.wav'

# multi-agent-shogun aliases (added by first_setup.sh)
css() { local s="shogun-$$"; local cols=$(tput cols 2>/dev/null || echo 80); tmux new-session -d -t shogun -s "$s" 2>/dev/null && tmux set-option -t "$s" destroy-unattached on 2>/dev/null; if [ "$cols" -lt 80 ]; then tmux new-window -t "$s" -n mobile 2>/dev/null; tmux attach-session -t "$s:mobile" 2>/dev/null || tmux attach-session -t shogun; else tmux attach-session -t "$s" 2>/dev/null || tmux attach-session -t shogun; fi; }
csm() { local s="multi-$$"; local cols=$(tput cols 2>/dev/null || echo 80); tmux new-session -d -t multiagent -s "$s" 2>/dev/null && tmux set-option -t "$s" destroy-unattached on 2>/dev/null; if [ "$cols" -lt 80 ]; then tmux new-window -t "$s" -n mobile 2>/dev/null; tmux attach-session -t "$s:mobile" 2>/dev/null || tmux attach-session -t multiagent; else tmux attach-session -t "$s" 2>/dev/null || tmux attach-session -t multiagent; fi; }
