# VoxOS

Mój Arch Linux z Hyprlandem, skrojony pod mnie. Jeden skrypt stawia cały system od zera.

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
dotfiles/           konfiguracja linkowana do ~ przez GNU Stow
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
| `Super + Shift + E` | wyloguj |

## Dodanie nowego hosta

Skopiuj `hosts/elitebook-1030` pod nową nazwą i zmień w nim sterowniki, usługi i monitory.
