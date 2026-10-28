-- VoxOS - główna konfiguracja Hyprlanda (wspólna dla wszystkich hostów i motywów)
-- Format Lua (Hyprland 0.55+). Dokumentacja: https://wiki.hypr.land/Configuring/Start/
-- Ustawienia konkretnego sprzętu (monitory, jasność, touchpad) są w host.lua

local terminal    = "kitty"
local menu        = "bash ~/.local/bin/voxos-launcher"
local fileManager = "thunar"
local mainMod     = "SUPER"

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    -- Przy autologinie (install.sh, AUTOLOGIN=true) ekran blokady motywu pełni rolę ekranu logowania
    hl.exec_cmd("bash ~/.local/bin/voxos-session-lock")
    hl.exec_cmd("waybar")
    hl.exec_cmd("mako")
    hl.exec_cmd("swaybg -i ~/.config/voxos/current/wallpaper.jpg -m fill -c '#000000'")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("udiskie --automount --notify")   -- pendrive'y montują się same
    hl.exec_cmd("blueman-applet")                  -- ikona Bluetooth w zasobniku
    hl.exec_cmd("hyprsunset")                      -- nocne światło (~/.config/hypr/hyprsunset.conf)
    hl.exec_cmd("thunar --daemon")                 -- szybsze otwieranie Thunara
    hl.exec_cmd("kdeconnect-indicator")            -- KDE Connect: telefon i tablet
end)

-- Kursor Bibata (motyw ustawiany też dla GTK w ~/.config/gtk-*/settings.ini)
hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_SIZE", "24")

---------------
---- WYGLĄD ----
---------------

hl.config({
    general = {
        layout = "dwindle",
        -- Przeciągane pływające okna przyklejają się do krawędzi ekranu i do innych okien
        snap = {
            enabled     = true,
            window_gap  = 10,
            monitor_gap = 10,
        },
    },

    animations = {
        enabled = true,
    },

    misc = {
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
    },
})

-- Kolory, ramki, cienie i rozmycie pochodzą z aktywnego motywu VoxOS
-- (theme.lua to symlink do themes/<motyw>/hypr.lua, przełączany przez voxos-theme)
local themeOk, themeErr = pcall(require, "theme")
if not themeOk then
    print("VoxOS: nie wczytano theme.lua: " .. tostring(themeErr))
end

------------------------------
---- KLAWIATURA I TOUCHPAD ----
------------------------------

hl.config({
    input = {
        kb_layout    = "pl",
        follow_mouse = 2,   -- fokus po kliknięciu (najechanie nie zmienia aktywnego okna, kółko myszy działa pod kursorem)
        touchpad = {
            natural_scroll = true,
        },
    },
})

---------------
---- SKRÓTY ----
---------------

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + D",      hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + Q",      hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exit())
hl.bind(mainMod .. " + F",      hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + Space",  hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + L",      hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("bash ~/.local/bin/voxos-power"))
hl.bind(mainMod .. " + T",      hl.dsp.exec_cmd("bash ~/.local/bin/voxos-theme"))
hl.bind(mainMod .. " + V",      hl.dsp.exec_cmd("cliphist list | rofi -dmenu | cliphist decode | wl-copy"))

hl.bind(mainMod .. " + S",      hl.dsp.exec_cmd("python3 ~/.local/bin/voxos-panel"))     -- panel szybkich ustawień
hl.bind(mainMod .. " + M",      hl.dsp.exec_cmd("bash ~/.local/bin/voxos-minimize"))           -- minimalizuj okno
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("bash ~/.local/bin/voxos-minimize restore")) -- przywróć zminimalizowane
hl.bind("ALT + Tab",              hl.dsp.exec_cmd("bash ~/.local/bin/voxos-alttab"))        -- przełącznik okien
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd("bash ~/.local/bin/voxos-dropdown"))  -- wysuwany terminal
hl.bind(mainMod .. " + K",         hl.dsp.exec_cmd("bash ~/.local/bin/voxos-calc"))           -- kalkulator (okno)
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.exec_cmd("bash ~/.local/bin/voxos-launcher files")) -- szukanie plików
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("bash ~/.local/bin/voxos-ocr"))           -- tekst z ekranu do schowka
-- Przyciąganie okien jak w Windowsie (voxos-snap)
hl.bind(mainMod .. " + ALT + left",  hl.dsp.exec_cmd("bash ~/.local/bin/voxos-snap left"))    -- lewa połowa
hl.bind(mainMod .. " + ALT + right", hl.dsp.exec_cmd("bash ~/.local/bin/voxos-snap right"))   -- prawa połowa
hl.bind(mainMod .. " + ALT + up",    hl.dsp.exec_cmd("bash ~/.local/bin/voxos-snap max"))     -- maksymalizacja
hl.bind(mainMod .. " + ALT + down",  hl.dsp.exec_cmd("bash ~/.local/bin/voxos-snap tile"))    -- z powrotem do kafelków
hl.bind(mainMod .. " + ALT + C",     hl.dsp.exec_cmd("bash ~/.local/bin/voxos-snap center"))  -- na środek
hl.bind(mainMod .. " + H",           hl.dsp.exec_cmd("bash ~/.local/bin/voxos-showdesktop"))  -- pokaż pulpit
hl.bind("CTRL + SHIFT + Escape",     hl.dsp.exec_cmd("bash ~/.local/bin/voxos-taskmgr"))      -- menedżer zadań
hl.bind(mainMod .. " + SHIFT + V",   hl.dsp.exec_cmd("bash ~/.local/bin/voxos-phone clip"))   -- schowek na telefon
hl.bind(mainMod .. " + slash",  hl.dsp.exec_cmd("bash ~/.local/bin/voxos-keys"))   -- ściągawka skrótów
hl.bind(mainMod .. " + N",      hl.dsp.exec_cmd("makoctl dismiss --all"))           -- schowaj powiadomienia
hl.bind(mainMod .. " + Tab",    hl.dsp.focus({ workspace = "previous" }))           -- poprzedni pulpit
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.exec_cmd("makoctl restore"))                -- przywróć ostatnie powiadomienie
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("bash ~/.local/bin/voxos-record"))  -- nagrywanie ekranu (start/stop)
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("bash ~/.local/bin/voxos-colorpicker")) -- próbnik kolorów
hl.bind(mainMod .. " + period",    hl.dsp.exec_cmd("rofi -modi emoji -show emoji"))     -- emoji (Super + .)

-- Zrzuty ekranu (plik w Obrazy/Zrzuty + kopia w schowku + powiadomienie z podglądem)
hl.bind("Print",         hl.dsp.exec_cmd("bash ~/.local/bin/voxos-screenshot area"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("bash ~/.local/bin/voxos-screenshot full"))
hl.bind("CTRL + Print",  hl.dsp.exec_cmd("bash ~/.local/bin/voxos-screenshot edit"))   -- zrzut od razu do edycji (satty)

-- Fokus strzałkami
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Przesuwanie okien: Super+Shift+strzałki
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }))

-- Zmiana rozmiaru okien: Super+Ctrl+strzałki (z powtarzaniem przy przytrzymaniu)
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.resize({ x = -40, y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x = 40,  y = 0,   relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.resize({ x = 0,   y = -40, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.resize({ x = 0,   y = 40,  relative = true }), { repeating = true })

-- Pulpity 1-9: Super+cyfra przełącza, Super+Shift+cyfra przenosi okno
for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

-- Przesuwanie i zmiana rozmiaru okien myszką
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
-- Upuszczenie pływającego okna przy krawędzi ekranu: połowa ekranu albo maksymalizacja (jak Snap w Windowsie)
hl.bind(mainMod .. " + mouse:272", hl.dsp.exec_cmd("bash ~/.local/bin/voxos-snap drop"), { drag = true, non_consuming = true })

-- Głośność z okienkiem OSD (działa też na zablokowanym ekranie, z powtarzaniem)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("bash ~/.local/bin/voxos-osd volume up"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("bash ~/.local/bin/voxos-osd volume down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("bash ~/.local/bin/voxos-osd volume mute"), { locked = true })
-- Muzyka i filmy (playerctl: Spotify, Firefox, mpv...)
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("bash ~/.local/bin/voxos-osd mic mute"),    { locked = true })

-- Gest: 3 palce w poziomie na touchpadzie = zmiana pulpitu
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

--------------------------
---- REGUŁY OKIEN ----
--------------------------

-- Okienka ustawień otwierają się jako pływające, wyśrodkowane, w rozsądnym rozmiarze
hl.window_rule({
    name   = "float-settings",
    match  = { class = "^(org.pulseaudio.pavucontrol|nm-connection-editor|blueman-manager|org.gnome.FileRoller|system-config-printer)$" },
    float  = true,
    center = true,
    size   = "900 600",
})

-- Wysuwany terminal (voxos-dropdown): pływający, u góry ekranu, na ukrytym pulpicie special:dropdown
hl.window_rule({
    name      = "dropdown-terminal",
    match     = { class = "^voxos-dropdown$" },
    float     = true,
    size      = { "monitor_w*0.7", "monitor_h*0.55" },
    move      = { "monitor_w*0.15", "60" },
    workspace = "special:dropdown silent",
})

-- Edycja zrzutów ekranu (satty): pływające okno na środku
hl.window_rule({
    name   = "satty",
    match  = { class = "^com.gabm.satty$" },
    float  = true,
    center = true,
})

-- Szybki podgląd plików (Spacja w Thunarze) i menedżer zadań: pływające na środku
hl.window_rule({
    name   = "quicklook",
    match  = { class = "^(org.gnome.NautilusPreviewer)$" },
    float  = true,
    center = true,
})
hl.window_rule({
    name   = "calculator",
    match  = { class = "^(org.gnome.Calculator)$" },
    float  = true,
    center = true,
    size   = { "380", "600" },
})
hl.window_rule({
    name   = "taskmgr",
    match  = { class = "^(io.missioncenter.MissionCenter)$" },
    float  = true,
    center = true,
    size   = { "monitor_w*0.7", "monitor_h*0.75" },
})

-- Obraz w obrazie z Firefoksa: pływający i widoczny na każdym pulpicie
hl.window_rule({
    name  = "firefox-pip",
    match = { title = "^(Obraz w obrazie|Picture-in-Picture)$" },
    float = true,
    pin   = true,
})

----------------------------------
---- USTAWIENIA KONKRETNEGO HOSTA ----
----------------------------------

-- host.lua to symlink do hosts/<host>/hypr-host.lua, tworzony przez install.sh
local ok, err = pcall(require, "host")
if not ok then
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
    print("VoxOS: nie wczytano host.lua: " .. tostring(err))
end
