# .zshrc ArchRicing — shell classique, PAS de raccourcis exotiques.
# Ctrl+C/V/X/Z/S/F gardent leur sens normal. Fastfetch au 1er terminal de session.
export EDITOR=nvim VISUAL=nvim PAGER=less
export BAT_THEME="TwoDark" EZA_ICONS_AUTO=1 FZF_DEFAULT_OPTS="--height 40% --reverse --border"

HISTFILE=~/.zsh_history HISTSIZE=50000 SAVEHIST=50000
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY AUTO_CD AUTO_PUSHD CORRECT

# Prompt Starship (thème ArchRicing)
command -v starship >/dev/null && eval "$(starship init zsh)"

# Plugins système (paquets zsh-autosuggestions / zsh-syntax-highlighting)
[[ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Alias modernes, non-destructifs
alias ls='eza --icons --group-directories-first'
alias ll='eza -l --icons --git'
alias la='eza -la --icons --git'
alias cat='bat --paging=never'
alias grep='grep --color=auto'
alias ..='cd ..' ...='cd ../..'
alias ff='fastfetch --config ~/.config/fastfetch/config.jsonc'
alias update='sudo pacman -Syu'
alias cleanup='sudo pacman -Rns $(pacman -Qdtq) 2>/dev/null || echo "nothing to clean"'

# fzf : Ctrl+R historique, Tab completion
command -v fzf >/dev/null && source /usr/share/fzf/key-bindings.zsh 2>/dev/null; command -v fzf >/dev/null && source /usr/share/fzf/completion.zsh 2>/dev/null

# Fastfetch uniquement au premier terminal interactif de la session (pas dans tmux imbriqué, pas en SSH non-interactif)
if [[ -o interactive && -z "$ARCHRICING_FF_SHOWN" && -z "$TMUX_NESTED" ]]; then
  export ARCHRICING_FF_SHOWN=1
  command -v fastfetch >/dev/null && fastfetch --config "${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/config.jsonc" 2>/dev/null || command -v fastfetch >/dev/null && fastfetch 2>/dev/null
fi

# PATH local (CLI archricing, apps)
export PATH="$HOME/.local/bin:$PATH"
