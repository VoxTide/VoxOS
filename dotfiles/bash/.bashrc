# VoxOS .bashrc
[[ $- != *i* ]] && return

# Własne skrypty VoxOS (voxos-theme, voxos-update, ...)
export PATH="$HOME/.local/bin:$PATH"
export EDITOR=nano

# Flutter, Android SDK i Java 17 (instaluje voxos-dev-setup)
[[ -d $HOME/development/flutter/bin ]] && export PATH="$HOME/development/flutter/bin:$PATH"
if [[ -d $HOME/Android/Sdk ]]; then
    export ANDROID_HOME="$HOME/Android/Sdk"
    export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
fi
[[ -d /usr/lib/jvm/java-17-openjdk ]] && export JAVA_HOME=/usr/lib/jvm/java-17-openjdk

# Historia: dużo, bez duplikatów, wspólna dla wszystkich terminali
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoreboth:erasedups
shopt -s histappend

# Podpowiedzi Tab dla komend (git, pacman, systemctl...)
[[ -r /usr/share/bash-completion/bash_completion ]] && source /usr/share/bash-completion/bash_completion

alias grep='grep --color=auto'
alias up='yay -Syu; pkill -RTMIN+8 waybar 2>/dev/null'   # aktualizacja całego systemu + odświeżenie licznika na pasku
alias snaps='sudo snapper -c root list'                  # lista migawek
alias hconf='$EDITOR ~/.config/hypr/hyprland.lua'

# Homelab (voxos-homelab-setup tworzy ~/.ssh/config.d/voxos i ~/.config/voxos/homelab.conf)
pihole-web() {
    local ip
    ip="$(. ~/.config/voxos/homelab.conf 2>/dev/null; echo "${PIHOLE_IP:-}")"
    if [[ -z $ip ]]; then echo "Najpierw: voxos-homelab-setup"; return 1; fi
    xdg-open "http://$ip/admin" >/dev/null 2>&1 &
}

# Kolorowe ls z ikonami (eza), kolorowy cat (bat) - z zapasowymi wersjami, gdyby ich nie było
if command -v eza >/dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -lah --icons --group-directories-first --git'
    alias lt='eza --tree --level=2 --icons'
else
    alias ls='ls --color=auto'
    alias ll='ls -lah'
fi
if command -v bat >/dev/null; then
    export BAT_THEME=ansi              # kolory z motywu terminala
    alias cat='bat --paging=never --style=plain'
fi
command -v fastfetch >/dev/null && alias ff='fastfetch'

# fzf: Ctrl+R szukanie w historii, Ctrl+T wstawianie plików, Alt+C wejście do folderu
if command -v fzf >/dev/null; then
    export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border=rounded --color=16"
    eval "$(fzf --bash)"
fi

# zoxide: "z proj" skacze do najczęściej używanego folderu pasującego do "proj"
command -v zoxide >/dev/null && eval "$(zoxide init bash)"

# Prompt: starship (kolory z motywu), a bez niego prosty zapasowy
PS1='\[\e[1;36m\]\u@\h\[\e[0m\] \w \$ '
command -v starship >/dev/null && eval "$(starship init bash)"
