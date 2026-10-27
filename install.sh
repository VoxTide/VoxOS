#!/usr/bin/env bash
# VoxOS - instalator konfiguracji Arch Linux + Hyprland
# Użycie: ./install.sh [nazwa-hosta]
# Bez argumentu bierze nazwę z /etc/hostname.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(realpath "$REPO_DIR/dotfiles")"
HOST="${1:-$(cat /etc/hostname)}"
HOST_DIR="$REPO_DIR/hosts/$HOST"

info() { printf '\e[1;36m==> %s\e[0m\n' "$*"; }
warn() { printf '\e[1;33m!! %s\e[0m\n' "$*"; }
die()  { printf '\e[1;31m!! %s\e[0m\n' "$*" >&2; exit 1; }

# Czyta listę pakietów: pomija komentarze (#) i puste linie
read_list() {
    sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$1"
}

# Przenosi istniejące pliki, które zablokowałyby stow, do kopii .bak
backup_conflicts() {
    local pkg="$1" rel target
    while IFS= read -r -d '' rel; do
        rel="${rel#./}"
        target="$HOME/$rel"
        if [[ -L $target ]] && [[ $(readlink -f "$target") == "$DOTFILES"/* ]]; then
            continue    # już nasz symlink
        fi
        if [[ -e $target || -L $target ]]; then
            warn "Kopia zapasowa: $target -> $target.bak"
            mv "$target" "$target.bak.$(date +%Y%m%d-%H%M%S)"
        fi
    done < <(cd "$DOTFILES/$pkg" && find . -type f -print0)
}

# --- Sprawdzenia -------------------------------------------------------------
[[ $EUID -ne 0 ]] || die "Uruchom jako zwykły użytkownik. Sudo zostanie użyte tam, gdzie trzeba."
[[ -f $HOST_DIR/host.conf ]] || die "Brak profilu dla hosta '$HOST'. Dostępne: $(ls "$REPO_DIR/hosts" | tr '\n' ' ')"
[[ -f $HOST_DIR/hypr-host.conf ]] || die "Brak pliku $HOST_DIR/hypr-host.conf"

# Domyślne wartości, nadpisywane przez host.conf
PKG_GROUPS=()
AUR_GROUPS=()
SERVICES=()
MASK_SERVICES=()
ENABLE_MULTILIB=false
# shellcheck source=/dev/null
source "$HOST_DIR/host.conf"

info "Profil hosta: $HOST"

# --- Repozytorium multilib (potrzebne np. dla Steam) --------------------------
if [[ $ENABLE_MULTILIB == true ]] && grep -q '^#\[multilib\]' /etc/pacman.conf; then
    info "Włączam repozytorium multilib"
    sudo sed -i '/^#\[multilib\]/{s/^#//;n;s/^#//}' /etc/pacman.conf
fi

# --- Pakiety z oficjalnych repozytoriów --------------------------------------
pkgs=()
for group in "${PKG_GROUPS[@]}"; do
    list="$REPO_DIR/packages/$group.txt"
    [[ -f $list ]] || die "Brak listy pakietów: packages/$group.txt"
    mapfile -t -O "${#pkgs[@]}" pkgs < <(read_list "$list")
done
if [[ -f $HOST_DIR/packages.txt ]]; then
    mapfile -t -O "${#pkgs[@]}" pkgs < <(read_list "$HOST_DIR/packages.txt")
fi

info "Instaluję ${#pkgs[@]} pakietów (pacman)"
sudo pacman -Syu --needed "${pkgs[@]}"

# --- Pakiety z AUR (przez paru) -----------------------------------------------
aur_pkgs=()
for group in "${AUR_GROUPS[@]}"; do
    list="$REPO_DIR/packages/$group.txt"
    [[ -f $list ]] || die "Brak listy pakietów: packages/$group.txt"
    mapfile -t -O "${#aur_pkgs[@]}" aur_pkgs < <(read_list "$list")
done

if (( ${#aur_pkgs[@]} > 0 )); then
    if ! command -v paru >/dev/null 2>&1; then
        info "Instaluję paru (pomocnik AUR)"
        tmp="$(mktemp -d)"
        git clone --depth 1 https://aur.archlinux.org/paru-bin.git "$tmp/paru-bin"
        (cd "$tmp/paru-bin" && makepkg -si --noconfirm)
        rm -rf "$tmp"
    fi
    info "Instaluję ${#aur_pkgs[@]} pakietów z AUR"
    paru -S --needed "${aur_pkgs[@]}"
fi

# --- Dotfiles -----------------------------------------------------------------
info "Linkuję dotfiles (GNU Stow)"
for dir in "$DOTFILES"/*/; do
    pkg="$(basename "$dir")"
    backup_conflicts "$pkg"
    stow --no-folding --restow -d "$DOTFILES" -t "$HOME" "$pkg"
done

info "Podpinam konfigurację Hyprlanda dla hosta $HOST"
mkdir -p "$HOME/.config/hypr"
ln -sfn "$HOST_DIR/hypr-host.conf" "$HOME/.config/hypr/host.conf"

# Foldery domowe (Obrazy, Pobrane itd.) w języku systemu
xdg-user-dirs-update

# --- Usługi systemowe -----------------------------------------------------------
info "Włączam usługi"
sudo systemctl enable NetworkManager.service sddm.service
if (( ${#SERVICES[@]} > 0 )); then
    sudo systemctl enable "${SERVICES[@]}"
fi
if (( ${#MASK_SERVICES[@]} > 0 )); then
    sudo systemctl mask "${MASK_SERVICES[@]}"
fi

# --- Firewall ------------------------------------------------------------------
if command -v ufw >/dev/null 2>&1; then
    info "Włączam firewall (ufw): blokuje ruch przychodzący, wychodzący bez zmian"
    if sudo ufw default deny incoming && sudo ufw default allow outgoing && sudo ufw --force enable; then
        sudo systemctl enable ufw.service
    else
        warn "Nie udało się włączyć ufw (zwykle po aktualizacji jądra). Po restarcie wpisz: sudo ufw enable"
    fi
fi

info "Gotowe. Zrestartuj komputer: sudo reboot"
