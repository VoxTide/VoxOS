# VoxOS

Mój Arch Linux z Hyprlandem, skrojony pod mnie. Jeden skrypt stawia cały system od zera.

## Motywy

| Motyw | Styl |
|-------|------|
| `nord` | [Nord](https://www.nordtheme.com): chłodne szaroniebieskie barwy, zorza nad górami |
| `dot` (domyślny) | monochromatyczny: czerń, biel i szarości z jednym czerwonym akcentem, zegar z kropek (font VoxDot), tapeta z półtonowej kuli |

Każdy motyw obejmuje: kolory okien Hyprlanda, pasek Waybar, rofi, powiadomienia mako, kolory terminala kitty i promptu starship, kolory aplikacji GTK3/GTK4 (okienka głośności, sieci, Bluetooth, Thunar, Loupe, Papers), ekran blokady i tapetę. Wspólne dla obu: baza adw-gtk3-dark, ikony Papirus-Dark, kursor Bibata-Modern-Ice.

```bash
voxos-theme          # menu wyboru (też Super + T)
voxos-theme dot      # od razu przełącz
voxos-theme --list   # dostępne motywy
```

Przy pierwszej instalacji motyw bierze się z `THEME=` w `hosts/<host>/host.conf`. Później obowiązuje ostatnio wybrany.

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
themes/<motyw>/     wygląd: hypr.lua, waybar, panel, rofi, mako, kitty, hyprlock, tapeta
boot/splash.bmp     logo VoxOS przy starcie
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
| `Super + S` | panel szybkich ustawień |
| `Super + strzałki` | fokus na sąsiednie okno |
| `Super + Shift + strzałki` | przesuń okno |
| `Super + Ctrl + strzałki` | zmień rozmiar okna |
| `Super + 1-9` albo klik w kropkę na pasku | przełącz pulpit |
| `Super + Shift + 1-9` | przenieś okno na pulpit |
| `Super + Tab` | poprzedni pulpit |
| 3 palce w bok (touchpad) | zmiana pulpitu |
| `Print` / `Shift + Print` | zrzut zaznaczenia / całego ekranu: plik w Obrazy/Zrzuty + schowek + powiadomienie |
| `Super + N` | schowaj powiadomienia |
| `Super + Shift + N` | przywróć ostatnie powiadomienie |
| `Super + Shift + R` | nagrywanie ekranu start/stop (Wideo/Nagrania) |
| `Super + Shift + C` | próbnik kolorów (HEX do schowka) |
| `Super + .` | emoji |
| klawisze multimedialne | muzyka: pauza, następny, poprzedni |
| `Super + /` | ściągawka skrótów |
| `Super + Escape` | menu zasilania (blokada, wyloguj, uśpij, restart, wyłącz) |
| `Super + T` | wybór motywu |
| `Super + Shift + E` | wyloguj |

## Wygoda na co dzień

- **Logowanie**: przy `AUTOLOGIN=true` w `host.conf` **greetd** uruchamia Hyprlanda od razu po starcie (bez serwera X, kilka sekund szybciej niż SDDM), a ekran blokady motywu (ten sam co `Super + L`) pełni rolę ekranu logowania, więc hasło jest wymagane (`voxos-session-lock`, log w `$XDG_RUNTIME_DIR/voxos-session-lock.log`). Wylogowanie wraca do tego samego ekranu blokady. `AUTOLOGIN=false` + `bash install.sh` przywraca klasyczny ekran SDDM. Awaryjnie: `Ctrl + Alt + F2`, zaloguj się i `sudo systemctl disable greetd && sudo systemctl enable sddm && sudo reboot`.
- **Cichy start**: przy `QUIET_BOOT=true` nie widać menu startowego ani przewijających się komunikatów, a zamiast logo Archa pojawia się logo VoxOS (`boot/splash.bmp`). Działa ze zwykłymi wpisami systemd-boot i z UKI (`/etc/kernel/cmdline` + preset mkinitcpio). Menu systemd-boot pokażesz, **przytrzymując Spację** zaraz po logo HP.
- **Pasek, prawa strona**: jedna pigułka z ikonami Wi-Fi, Bluetooth, głośności i baterii. Klik (albo `Super + S`) otwiera **panel szybkich ustawień** (`voxos-panel`): bateria z czasem, zrzut ekranu, motyw, blokada, zasilanie, suwaki głośności i jasności, kafelki Wi-Fi (strzałka: lista sieci z hasłem), Bluetooth, nocne światło, nie przeszkadzać, mikrofon, bez usypiania, tryb samolotowy, telefon (KDE Connect) i odtwarzacz muzyki. Zamykanie: klik obok, `Esc` albo ponowny klik w pasek. Klik w baterię na pasku pokazuje procent i czas do rozładowania / do pełna. Kółko na głośności zmienia głośność, prawy klik wycisza. Licznik aktualizacji pojawia się tylko, gdy są nowe pakiety.
- **Launcher i menu** (aplikacje, zasilanie, motywy, schowek, panel) zamykają się kliknięciem obok okna albo `Esc`.
- **OSD**: przy zmianie głośności i jasności pojawia się okienko z paskiem (`voxos-osd`).
- **Bateria**: ostrzeżenie przy 20% i alarm przy 10% (`voxos-battery`, timer systemd co 2 minuty).
- **Aktualizacje**: licznik na pasku, gdy są nowe pakiety. Kliknięcie otwiera terminal z aktualizacją.
- **Nocne światło**: od 20:00 cieplejsze kolory, od 22:30 jeszcze cieplejsze, od 7:00 normalne (`~/.config/hypr/hyprsunset.conf`).
- **Pliki**: miniatury, archiwa (Rozpakuj tutaj), kosz i pendrive'y montowane automatycznie. Zdjęcia: Loupe, PDF: Papers, wideo: mpv. Bluetooth: ikona w zasobniku.
- **Okienka ustawień** (głośność, sieć, Bluetooth, archiwa) otwierają się jako pływające. Obraz w obrazie z Firefoksa jest widoczny na każdym pulpicie.
- **Terminal**: prompt starship w kolorach motywu, `Ctrl+R` szukanie w historii (fzf), `z <folder>` skakanie po folderach (zoxide), `ls`/`ll`/`lt` z ikonami (eza), kolorowy `cat` (bat), `ff` = fastfetch, podpowiedzi Tab.

Okna aktywują się **po kliknięciu** (samo najechanie myszą nie zmienia aktywnego okna, kółko myszy działa pod kursorem).

## Programowanie, studia, homelab

Jednorazowe skrypty (można je uruchamiać ponownie, niczego nie psują):

```bash
voxos-dev-setup        # Flutter 3.47.7, Android SDK, Claude Code, rozszerzenia VS Code, klucz SSH
voxos-homelab-setup    # ssh zomboid / ssh pihole bez hasła, pihole-web otwiera panel Pi-hole
voxos-backup           # kopia Dokumentów, Obrazów, projektów itd. na serwer (rsync, ustawienia w ~/.config/voxos/backup.conf)
```

- **Telefon w trybie debugowania USB** + kabel: `adb devices`, potem `flutter run` w folderze projektu.
- **Studia**: LibreOffice po polsku ze słownikiem, czcionki zgodne z dokumentami z Worda (Liberation, Carlito, Caladea), w VS Code „Live Preview” do podglądu strony HTML na żywo.
- **KDE Connect**: aplikacja KDE Connect na telefonie (na tablecie działa też Zorin Connect), ikona w zasobniku, porty 1714-1764 otwarte w ufw.

## Aktualizacja z pliku zip

Nową wersję repo w pliku `voxos.zip` (np. od Claude) wgrywa jedna komenda na laptopie:

```bash
voxos-update                      # najnowszy voxos*.zip z folderu Pobrane
voxos-update -m "opis zmian"      # opis commita od razu
```

Skrypt sprawdza, czy repo jest czyste i czy zip to na pewno VoxOS, pobiera najpierw zmiany z GitHuba, podmienia pliki (oprócz `.git`), pokazuje listę zmian, robi commit i `git push`, a potem uruchamia `install.sh --quick` (dotfiles i motyw, bez pakietów). Pełną instalację z pakietami wybierasz w pytaniu na końcu.

Jednorazowo przed pierwszym użyciem: `gh auth login` oraz `git config --global user.name` / `user.email`.

## Pakiety z gita zamiast repozytoriów

`GIT_FALLBACK` w `install.sh`: dopóki wydanie w repozytoriach czegoś nie umie, instalowana jest wersja `-git` z AUR. Teraz: **waybar-git** (klik w pulpit na pasku przy configu Lua) i **rofi-git** (zamykanie kliknięciem obok). Gdy w repozytoriach pojawi się nowsza wersja, `bash install.sh` sam wraca do zwykłego pakietu.

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
