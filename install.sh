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
THEME=dot
AUTOLOGIN=false
QUIET_BOOT=false
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

# --- Wersje -git tam, gdzie wydanie z repozytoriów czegoś jeszcze nie umie ------
# "pakiet wersja": dopóki repozytorium ma wersję <= podanej, instalujemy pakiet-git z AUR.
# Gdy w repozytorium pojawi się nowsza wersja, install.sh sam wraca do zwykłego pakietu.
GIT_FALLBACK=(
    "waybar 0.15.0"   # klik w pulpit na pasku przy configu Hyprlanda w Lua (poprawka jest w gicie)
    "rofi 2.0.0"      # zamykanie launchera i menu kliknięciem obok okna (Wayland, poprawka w gicie)
)
git_aur=()
for entry in "${GIT_FALLBACK[@]}"; do
    read -r name max <<<"$entry"
    repo_ver=$(pacman -Si -- "$name" 2>/dev/null | awk '/^Version/ { print $3; exit }')
    [[ -n $repo_ver ]] || continue
    if (( $(vercmp "$repo_ver" "$max") <= 0 )); then
        for i in "${!pkgs[@]}"; do
            [[ ${pkgs[i]} == "$name" ]] && unset 'pkgs[i]'
        done
        git_aur+=("$name-git")
    elif pacman -Q "$name-git" >/dev/null 2>&1; then
        info "$name $repo_ver jest już w repozytoriach - wracam z $name-git na zwykły pakiet (potwierdź usunięcie $name-git)"
    fi
done
pkgs=("${pkgs[@]}")

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
aur_pkgs+=("${git_aur[@]}")

if (( ${#aur_pkgs[@]} > 0 )); then
    # Budujemy yay ze źródeł, żeby zawsze pasował do aktualnej wersji pacmana
    if ! yay --version >/dev/null 2>&1; then
        info "Instaluję yay (pomocnik AUR, kompilacja ze źródeł)"
        tmp="$(mktemp -d)"
        git clone --depth 1 https://aur.archlinux.org/yay.git "$tmp/yay"
        (cd "$tmp/yay" && makepkg -si --noconfirm)
        rm -rf "$tmp"
    fi
    for p in "${git_aur[@]}"; do
        if ! pacman -Q "$p" >/dev/null 2>&1 && pacman -Q "${p%-git}" >/dev/null 2>&1; then
            warn "$p zastąpi ${p%-git}: na pytanie o usunięcie ${p%-git} odpowiedz y (kompilacja potrwa kilka-kilkanaście minut)"
        fi
    done
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
sudo systemctl enable NetworkManager.service
if (( ${#SERVICES[@]} > 0 )); then
    sudo systemctl enable "${SERVICES[@]}"
fi
if (( ${#MASK_SERVICES[@]} > 0 )); then
    sudo systemctl mask "${MASK_SERVICES[@]}"
fi

# --- Logowanie ------------------------------------------------------------------
# AUTOLOGIN=true: greetd od razu uruchamia Hyprlanda (bez serwera X, szybciej niż SDDM),
#   a ekran blokady motywu (voxos-session-lock) pełni rolę ekranu logowania.
# AUTOLOGIN=false: klasyczny ekran logowania SDDM.
AUTOLOGIN_MARK=/etc/voxos/autologin
OLD_SDDM_AUTOLOGIN=/etc/sddm.conf.d/voxos-autologin.conf

session_desktop="$(ls /usr/share/wayland-sessions/hyprland.desktop /usr/share/wayland-sessions/hyprland*.desktop 2>/dev/null | head -1)"
session_cmd=""
[[ -n $session_desktop ]] && session_cmd="$(grep -m1 '^Exec=' "$session_desktop" | cut -d= -f2-)"

if [[ $AUTOLOGIN == true && -x /usr/bin/greetd && -n $session_cmd ]]; then
    info "Logowanie: greetd uruchamia Hyprlanda od razu, hasło na ekranie blokady motywu"
    sudo mkdir -p /etc/greetd /etc/voxos
    # initial_session = start komputera, default_session = po wylogowaniu (znów prosto do blokady)
    # Wyjście Hyprlanda idzie do /dev/null, żeby jego powitanie nie mignęło na ekranie (log i tak jest w $XDG_RUNTIME_DIR/hypr)
    sudo tee /etc/greetd/config.toml >/dev/null <<GREETD
# VoxOS - logowanie przez greetd (wygenerowane przez install.sh, zmiany rób w repo)
[terminal]
vt = 1

[initial_session]
command = "$session_cmd >/dev/null 2>&1"
user = "$USER"

[default_session]
command = "$session_cmd >/dev/null 2>&1"
user = "$USER"
GREETD
    sudo touch "$AUTOLOGIN_MARK"
    sudo rm -f "$OLD_SDDM_AUTOLOGIN"
    sudo systemctl disable sddm.service >/dev/null 2>&1 || true
    sudo systemctl enable greetd.service
else
    if [[ $AUTOLOGIN == true ]]; then
        warn "Brak greetd albo sesji Hyprlanda - zostaję przy ekranie logowania SDDM"
    fi
    sudo rm -f "$AUTOLOGIN_MARK" "$OLD_SDDM_AUTOLOGIN"
    sudo systemctl disable greetd.service >/dev/null 2>&1 || true
    sudo systemctl enable sddm.service
fi

# --- Cichy start: bez menu, bez komunikatów, logo VoxOS zamiast logo Archa --------
# Obsługuje oba układy systemd-boot: zwykłe wpisy (loader/entries) oraz UKI
# (jądro w jednym pliku .efi, parametry w /etc/kernel/cmdline, logo w presecie mkinitcpio).
if [[ $QUIET_BOOT == true ]] && command -v bootctl >/dev/null 2>&1; then
    esp="$(bootctl --print-esp-path 2>/dev/null || echo /boot)"
    quiet_params=(quiet loglevel=3 systemd.show_status=auto rd.systemd.show_status=auto rd.udev.log_level=3 vt.global_cursor_default=0)
    rebuild_uki=false
    info "Cichy start: ukrywam menu i komunikaty (menu startowe: przytrzymaj Spację po logo HP)"

    # Menu systemd-boot bez odliczania
    if sudo test -f "$esp/loader/loader.conf"; then
        if sudo grep -q '^timeout' "$esp/loader/loader.conf"; then
            sudo sed -i 's/^timeout.*/timeout 0/' "$esp/loader/loader.conf"
        else
            echo 'timeout 0' | sudo tee -a "$esp/loader/loader.conf" >/dev/null
        fi
    fi

    # Układ 1: zwykłe wpisy systemd-boot
    while IFS= read -r entry; do
        for p in "${quiet_params[@]}"; do
            sudo grep -Eq "^options.*(^|[[:space:]])${p}([[:space:]]|$)" "$entry" \
                || sudo sed -i "/^options /s/\$/ ${p}/" "$entry"
        done
    done < <(sudo find "$esp/loader/entries" -name '*.conf' 2>/dev/null)

    # Układ 2: UKI - parametry jądra w /etc/kernel/cmdline
    if [[ -f /etc/kernel/cmdline ]]; then
        for p in "${quiet_params[@]}"; do
            if ! grep -Eq "(^|[[:space:]])${p}([[:space:]]|$)" /etc/kernel/cmdline; then
                sudo sed -i "1s/\$/ ${p}/" /etc/kernel/cmdline
                rebuild_uki=true
            fi
        done
    fi

    # Logo VoxOS zamiast logo Archa (UKI pokazuje obrazek z opcji --splash)
    splash=/usr/share/voxos/splash.bmp
    if ! sudo cmp -s "$REPO_DIR/boot/splash.bmp" "$splash"; then
        sudo install -Dm644 "$REPO_DIR/boot/splash.bmp" "$splash"
        rebuild_uki=true
    fi
    for preset in /etc/mkinitcpio.d/*.preset; do
        [[ -f $preset ]] || continue
        if grep -q -- '--splash' "$preset" && ! grep -q -- "--splash $splash" "$preset"; then
            sudo sed -i -E "s#--splash[[:space:]]+[^\" ]+#--splash $splash#g" "$preset"
            rebuild_uki=true
        fi
    done

    if [[ $rebuild_uki == true ]] && compgen -G "/etc/mkinitcpio.d/*.preset" >/dev/null; then
        info "Przebudowuję obraz startowy (mkinitcpio -P), to potrwa chwilę"
        sudo mkinitcpio -P || warn "mkinitcpio zgłosił problem - sprawdź komunikaty powyżej przed restartem"
    fi
fi

# --- Firewall ------------------------------------------------------------------
if command -v ufw >/dev/null 2>&1; then
    info "Włączam firewall (ufw): blokuje ruch przychodzący, wychodzący bez zmian"
    if sudo ufw default deny incoming && sudo ufw default allow outgoing && sudo ufw --force enable; then
        # KDE Connect (telefon, tablet) potrzebuje portów 1714-1764 w sieci lokalnej
        if command -v kdeconnect-cli >/dev/null 2>&1; then
            sudo ufw allow 1714:1764/udp comment 'KDE Connect' >/dev/null
            sudo ufw allow 1714:1764/tcp comment 'KDE Connect' >/dev/null
        fi
        sudo systemctl enable ufw.service
    else
        warn "Nie udało się włączyć ufw (zwykle po aktualizacji jądra). Po restarcie wpisz: sudo ufw enable"
    fi
fi

info "Gotowe. Zrestartuj komputer: sudo reboot"
