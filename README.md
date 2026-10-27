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
git clone https://github.com/VoxTide/VoxOS.git ~/voxos
cd ~/voxos
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
| `Super + Q` albo X przy tytule okna na pasku | zamknij okno |
| `Super + F` | pełny ekran |
| `Super + Spacja` | okno pływające |
| `Super + L` | blokada ekranu |
| `Super + V` | historia schowka |
| `Super + strzałki` | fokus na sąsiednie okno |
| `Super + Shift + strzałki` | przesuń okno |
| `Super + Ctrl + strzałki` | zmień rozmiar okna |
| `Super + 1-9` | przełącz pulpit |
| `Super + Shift + 1-9` | przenieś okno na pulpit |
| `Super + Tab` | poprzedni pulpit |
| 3 palce w bok (touchpad) | zmiana pulpitu |
| `Print` / `Shift + Print` | zrzut zaznaczenia / całego ekranu: plik w Obrazy/Zrzuty + schowek + powiadomienie |
| `Super + N` | schowaj powiadomienia |
| `Super + /` | ściągawka skrótów |
| `Super + Escape` | menu zasilania (blokada, wyloguj, uśpij, restart, wyłącz) |
| `Super + T` | wybór motywu |
| `Super + Shift + E` | wyloguj |

## Wygoda na co dzień

- **OSD**: przy zmianie głośności i jasności pojawia się okienko z paskiem (`voxos-osd`).
- **Bateria**: ostrzeżenie przy 20% i alarm przy 10% (`voxos-battery`, timer systemd co 2 minuty).
- **Aktualizacje**: licznik na pasku, gdy są nowe pakiety. Kliknięcie otwiera terminal z aktualizacją.
- **Nocne światło**: od 20:00 cieplejsze kolory, od 22:30 jeszcze cieplejsze, od 7:00 normalne (`~/.config/hypr/hyprsunset.conf`).
- **Pliki**: miniatury, archiwa (Rozpakuj tutaj), kosz i pendrive'y montowane automatycznie. Zdjęcia: Loupe, PDF: Papers, wideo: mpv. Bluetooth: ikona w zasobniku.
- **Okienka ustawień** (głośność, sieć, Bluetooth, archiwa) otwierają się jako pływające. Obraz w obrazie z Firefoksa jest widoczny na każdym pulpicie.
- **Terminal**: prompt starship w kolorach motywu, `Ctrl+R` szukanie w historii (fzf), `z <folder>` skakanie po folderach (zoxide), `ls`/`ll`/`lt` z ikonami (eza), kolorowy `cat` (bat), `ff` = fastfetch, podpowiedzi Tab.

## Aktualizacja z pliku zip

Nową wersję repo w pliku `voxos.zip` (np. od Claude) wgrywa jedna komenda na laptopie:

```bash
voxos-update                      # najnowszy voxos*.zip z folderu Pobrane
voxos-update -m "opis zmian"      # opis commita od razu
```

Skrypt sprawdza, czy repo jest czyste i czy zip to na pewno VoxOS, pobiera najpierw zmiany z GitHuba, podmienia pliki (oprócz `.git`), pokazuje listę zmian, robi commit i `git push`, a potem uruchamia `install.sh --quick` (dotfiles i motyw, bez pakietów). Pełną instalację z pakietami wybierasz w pytaniu na końcu.

Jednorazowo przed pierwszym użyciem: `gh auth login` oraz `git config --global user.name` / `user.email`.

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
