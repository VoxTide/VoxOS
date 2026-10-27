#!/usr/bin/env bash
# VoxOS - instalator konfiguracji Arch Linux + Hyprland
# Użycie: ./install.sh [nazwa-hosta]
# Bez argumentu bierze nazwę z /etc/hostname.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(realpath "$REPO_DIR/dotfiles")"
# --quick: tylko dotfiles, motyw i wygląd, bez pakietów i usług (używa voxos-update)
QUICK=false
if [[ ${1:-} == --quick ]]; then QUICK=true; shift; fi
HOST="${1:-$(cat /etc/hostname)}"
HOST_DIR="$REPO_DIR/hosts/$HOST"

info() { printf '\e[1;36m==> %s\e[0m\n' "$*"; }
warn() { printf '\e[1;33m!! %s\e[0m\n' "$*"; }
die()  { printf '\e[1;31m!! %s\e[0m\n' "$*" >&2; exit 1; }

# Czyta listę pakietów: pomija komentarze (#) i puste linie
read_list() {
    sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$1"
}

# Usuwa zerwane symlinki do repo (pliki, które zniknęły z repo, np. stary hyprland.conf)
cleanup_dead_links() {
    local link
    while IFS= read -r -d '' link; do
        if [[ $(readlink -m "$link") == "$REPO_DIR"/* ]]; then
            info "Usuwam nieaktualny symlink: $link"
            rm "$link"
        fi
    done < <(find "$HOME" -maxdepth 4 -xtype l -print0 2>/dev/null)
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
[[ -f $HOST_DIR/hypr-host.lua ]] || die "Brak pliku $HOST_DIR/hypr-host.lua"

# Domyślne wartości, nadpisywane przez host.conf
PKG_GROUPS=()
AUR_GROUPS=()
SERVICES=()
MASK_SERVICES=()
ENABLE_MULTILIB=false
SNAPPER=false
THEME=nord
AUTOLOGIN=false
# shellcheck source=/dev/null
source "$HOST_DIR/host.conf"

info "Profil hosta: $HOST"

if [[ $QUICK == false ]]; then   # >>> pakiety (pomijane w trybie --quick)

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

info "Odświeżam bazy pakietów"
sudo pacman -Sy

# Nazwy, których nie ma w repozytoriach, pomijamy z ostrzeżeniem zamiast przerywać całą instalację
known=()
missing=()
for p in "${pkgs[@]}"; do
    if pacman -Si -- "$p" >/dev/null 2>&1 || pacman -Sg -- "$p" >/dev/null 2>&1; then
        known+=("$p")
    else
        missing+=("$p")
    fi
done
if (( ${#missing[@]} > 0 )); then
    warn "Pomijam pakiety, których nie ma w repozytoriach: ${missing[*]}"
fi

info "Instaluję ${#known[@]} pakietów i aktualizuję system (pacman)"
sudo pacman -Su --needed "${known[@]}"

# --- Pakiety z AUR (przez yay) -------------------------------------------------
aur_pkgs=()
for group in "${AUR_GROUPS[@]}"; do
    list="$REPO_DIR/packages/$group.txt"
    [[ -f $list ]] || die "Brak listy pakietów: packages/$group.txt"
    mapfile -t -O "${#aur_pkgs[@]}" aur_pkgs < <(read_list "$list")
done

if (( ${#aur_pkgs[@]} > 0 )); then
    # Budujemy yay ze źródeł, żeby zawsze pasował do aktualnej wersji pacmana
    if ! yay --version >/dev/null 2>&1; then
        info "Instaluję yay (pomocnik AUR, kompilacja ze źródeł)"
        tmp="$(mktemp -d)"
        git clone --depth 1 https://aur.archlinux.org/yay.git "$tmp/yay"
        (cd "$tmp/yay" && makepkg -si --noconfirm)
        rm -rf "$tmp"
    fi
    info "Instaluję ${#aur_pkgs[@]} pakietów z AUR"
    yay -S --needed "${aur_pkgs[@]}" || warn "Część pakietów z AUR się nie zainstalowała - reszta instalacji idzie dalej"
fi

# --- Migawki przy aktualizacjach (snapper + snap-pac) ------------------------------
if [[ $SNAPPER == true ]]; then
    if sudo snapper list-configs 2>/dev/null | grep -qw root; then
        info "Włączam migawki przy każdej instalacji i aktualizacji (snap-pac)"
        sudo pacman -S --needed snap-pac
        sudo systemctl enable --now snapper-cleanup.timer
    else
        warn "Brak konfiguracji snappera 'root' - pomijam snap-pac (sprawdź: sudo snapper list-configs)"
    fi
fi

fi   # <<< koniec sekcji pakietów

# --- Dotfiles -----------------------------------------------------------------
cleanup_dead_links

info "Linkuję dotfiles (GNU Stow)"
for dir in "$DOTFILES"/*/; do
    pkg="$(basename "$dir")"
    backup_conflicts "$pkg"
    stow --no-folding --restow -d "$DOTFILES" -t "$HOME" "$pkg"
done

info "Odświeżam pamięć czcionek"
fc-cache -f >/dev/null

info "Podpinam konfigurację Hyprlanda dla hosta $HOST"
mkdir -p "$HOME/.config/hypr"
ln -sfn "$HOST_DIR/hypr-host.lua" "$HOME/.config/hypr/host.lua"

# Motyw VoxOS: zostaje aktualny, a przy pierwszej instalacji bierzemy THEME z host.conf
theme="$THEME"
if [[ -L $HOME/.config/voxos/current ]]; then
    current="$(basename "$(readlink -f "$HOME/.config/voxos/current")")"
    [[ -d $REPO_DIR/themes/$current ]] && theme="$current"
fi
info "Ustawiam motyw: $theme (zmiana później: voxos-theme albo Super + T)"
bash "$DOTFILES/scripts/.local/bin/voxos-theme" "$theme"

# Ciemny motyw aplikacji GTK/libadwaita (Firefox, Thunar, okna dialogowe)
gtk_theme=Adwaita-dark
[[ -d /usr/share/themes/adw-gtk3-dark ]] && gtk_theme=adw-gtk3-dark   # kolory z motywu VoxOS także w GTK3
if command -v gsettings >/dev/null 2>&1; then
    info "Ustawiam ciemny motyw aplikacji, ikony Papirus i kursor Bibata"
    {
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' &&
        gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme" &&
        gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' &&
        gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Ice' &&
        gsettings set org.gnome.desktop.interface cursor-size 24
    } || warn "Nie udało się ustawić motywu przez gsettings (uruchom instalator z poziomu Hyprlanda)"
fi

# Domyślne aplikacje dla zdjęć, PDF i wideo (tylko jeśli są zainstalowane)
set_default() {
    local desktop="$1"; shift
    [[ -f /usr/share/applications/$desktop ]] || return 0
    xdg-mime default "$desktop" "$@" 2>/dev/null || true
}
set_default org.gnome.Loupe.desktop  image/png image/jpeg image/gif image/webp image/bmp image/svg+xml
set_default org.gnome.Papers.desktop application/pdf
set_default mpv.desktop              video/mp4 video/x-matroska video/webm video/quicktime audio/mpeg audio/flac audio/ogg
set_default thunar.desktop           inode/directory

# Usługi użytkownika VoxOS (alarm baterii)
if systemctl --user show-environment >/dev/null 2>&1; then
    systemctl --user daemon-reload
    systemctl --user enable --now voxos-battery.timer >/dev/null 2>&1 \
        || warn "Nie udało się włączyć voxos-battery.timer"
fi

# Foldery domowe (Obrazy, Pobrane itd.) w języku systemu
xdg-user-dirs-update

if [[ $QUICK == true ]]; then
    info "Gotowe (tryb szybki: bez pakietów i usług)"
    exit 0
fi

# --- Usługi systemowe -----------------------------------------------------------
info "Włączam usługi"
sudo systemctl enable NetworkManager.service sddm.service
if (( ${#SERVICES[@]} > 0 )); then
    sudo systemctl enable "${SERVICES[@]}"
fi
if (( ${#MASK_SERVICES[@]} > 0 )); then
    sudo systemctl mask "${MASK_SERVICES[@]}"
fi

# --- Logowanie: autologin + ekran blokady z motywu jako ekran logowania ----------
AUTOLOGIN_CONF=/etc/sddm.conf.d/voxos-autologin.conf
if [[ $AUTOLOGIN == true ]]; then
    session=hyprland
    [[ -f /usr/share/wayland-sessions/hyprland.desktop ]] || \
        session="$(basename "$(ls /usr/share/wayland-sessions/hyprland*.desktop 2>/dev/null | head -1)" .desktop)"
    if [[ -n $session ]]; then
        info "Logowanie: autologin do Hyprlanda, hasło na ekranie blokady motywu"
        sudo mkdir -p /etc/sddm.conf.d
        printf '[Autologin]\nUser=%s\nSession=%s\nRelogin=true\n' "$USER" "$session" \
            | sudo tee "$AUTOLOGIN_CONF" >/dev/null
    else
        warn "Nie znalazłem sesji Hyprlanda w /usr/share/wayland-sessions - pomijam autologin"
    fi
elif [[ -f $AUTOLOGIN_CONF ]]; then
    info "Wyłączam autologin (AUTOLOGIN=false)"
    sudo rm -f "$AUTOLOGIN_CONF"
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
