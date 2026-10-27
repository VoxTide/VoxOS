# VoxOS

Mój Arch Linux z Hyprlandem, skrojony pod mnie. Jeden skrypt stawia cały system od zera.

## Motywy

| Motyw | Styl |
|-------|------|
| `nord` | [Nord](https://www.nordtheme.com): chłodne szaroniebieskie barwy, zorza nad górami |
| `dot` | monochromatyczny: czerń, biel i szarości z jednym czerwonym akcentem, zegar z kropek (font VoxDot), tapeta z półtonowej kuli |

Każdy motyw obejmuje: kolory okien Hyprlanda, pasek Waybar, rofi, powiadomienia mako, kolory terminala kitty, ekran blokady i tapetę. Wspólne dla obu: ciemne aplikacje GTK (Adwaita-dark), ikony Papirus-Dark, kursor Bibata-Modern-Ice.

```bash
voxos-theme          # menu wyboru (też Super + T)
voxos-theme dot      # od razu przełącz
voxos-theme --list   # dostępne motywy
```

Przełączenie podmienia jeden symlink `~/.config/voxos/current -> themes/<motyw>` i przeładowuje Hyprlanda, pasek, tapetę, powiadomienia i terminale. Wybór przetrwa restart i ponowne uruchomienie `install.sh`.

Nowy motyw: skopiuj `themes/nord` pod nową nazwą i zmień pliki. Tapety generują skrypty `themes/<motyw>/generate-wallpaper.py`.

## Hosty

| Host | Sprzęt | Status |
|------|--------|--------|
| `elitebook-1030` | HP EliteBook 1030 G1 | w budowie |
| `desktop` | Ryzen 7 5800X3D + RX 9060 XT | później |

## Instalacja

1. Zainstaluj Arch przez `archinstall`:
   - **Hostname:** `elitebook-1030` (musi pasować do folderu w `hosts/`)
   - **Profile:** Minimal
   - **Audio:** Pipewire
   - **Network:** NetworkManager
   - utwórz zwykłego użytkownika z uprawnieniami sudo
2. Po restarcie zaloguj się w konsoli i uruchom:

```bash
sudo pacman -S git
git clone https://github.com/VoxTide/voxos.git
cd voxos
bash install.sh
sudo reboot
```

Istniejące pliki konfiguracyjne nie zostaną nadpisane bez śladu: skrypt robi ich kopię z końcówką `.bak.<data>`.

## Struktura

```
install.sh          główny skrypt
packages/           listy pakietów (base, dev, aur-dev)
hosts/<host>/
  host.conf         grupy pakietów, usługi
  packages.txt      sterowniki i pakiety tylko dla tego sprzętu
  hypr-host.lua     monitory, jasność, touchpad (Lua)
dotfiles/           wspólna konfiguracja linkowana do ~ przez GNU Stow
themes/<motyw>/     wygląd: hypr.lua, waybar, rofi, mako, kitty, hyprlock, tapeta
```

## Najważniejsze skróty

| Skrót | Akcja |
|-------|-------|
| `Super + Enter` | terminal |
| `Super + D` | launcher aplikacji |
| `Super + E` | menedżer plików |
| `Super + Q` | zamknij okno |
| `Super + F` | pełny ekran |
| `Super + Spacja` | okno pływające |
| `Super + L` | blokada ekranu |
| `Super + V` | historia schowka |
| `Super + 1-9` | przełącz pulpit |
| `Super + Shift + 1-9` | przenieś okno na pulpit |
| `Print` | zrzut zaznaczenia do schowka |
| `Shift + Print` | zrzut ekranu do Obrazy/Zrzuty |
| `Super + Escape` | menu zasilania (blokada, wyloguj, uśpij, restart, wyłącz) |
| `Super + T` | wybór motywu |
| `Super + Shift + E` | wyloguj |

## Migawki (snapper + snap-pac)

Każda instalacja, usunięcie i aktualizacja pakietów (`pacman`, `yay`, alias `up`) robi dwie migawki: **pre** (przed) i **post** (po).

```bash
snaps                                   # lista migawek, np. 41 pre / 42 post
sudo snapper -c root status 41..42      # co zmieniła aktualizacja
sudo snapper -c root undochange 41..42  # cofnij zmiany z tej aktualizacji
sudo reboot
```

Stare migawki usuwa automatycznie `snapper-cleanup.timer`.

## Dodanie nowego hosta

Skopiuj `hosts/elitebook-1030` pod nową nazwą i zmień w nim sterowniki, usługi i monitory.
