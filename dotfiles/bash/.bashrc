# VoxOS .bashrc
[[ $- != *i* ]] && return

# Własne skrypty VoxOS (voxos-theme, voxos-power)
export PATH="$HOME/.local/bin:$PATH"

alias ls='ls --color=auto'
alias ll='ls -lah'
alias grep='grep --color=auto'
alias up='yay -Syu'           # aktualizacja całego systemu (repo + AUR)
alias snaps='sudo snapper -c root list'   # lista migawek
alias hconf='$EDITOR ~/.config/hypr/hyprland.lua'

export EDITOR=nano
PS1='\[\e[1;36m\]\u@\h\[\e[0m\] \w \$ '
