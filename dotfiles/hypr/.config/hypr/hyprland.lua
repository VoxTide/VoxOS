-- VoxOS - główna konfiguracja Hyprlanda (wspólna dla wszystkich hostów i motywów)
-- Format Lua (Hyprland 0.55+). Dokumentacja: https://wiki.hypr.land/Configuring/Start/
-- Ustawienia konkretnego sprzętu (monitory, jasność, touchpad) są w host.lua

local terminal    = "kitty"
local menu        = "rofi -show drun"
local fileManager = "thunar"
local mainMod     = "SUPER"

-------------------
---- AUTOSTART ----
-------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("mako")
    hl.exec_cmd("swaybg -i ~/.config/voxos/current/wallpaper.jpg -m fill -c '#000000'")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
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
        follow_mouse = 1,
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

-- Zrzuty ekranu: Print = zaznaczenie do schowka, Shift+Print = cały ekran do pliku
hl.bind("Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd(
    'mkdir -p "$(xdg-user-dir PICTURES)/Zrzuty" && grim "$(xdg-user-dir PICTURES)/Zrzuty/$(date +%F_%H-%M-%S).png"'))

-- Fokus strzałkami
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Pulpity 1-9: Super+cyfra przełącza, Super+Shift+cyfra przenosi okno
for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

-- Przesuwanie i zmiana rozmiaru okien myszką
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Głośność (działa też na zablokowanym ekranie, z powtarzaniem)
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })

----------------------------------
---- USTAWIENIA KONKRETNEGO HOSTA ----
----------------------------------

-- host.lua to symlink do hosts/<host>/hypr-host.lua, tworzony przez install.sh
local ok, err = pcall(require, "host")
if not ok then
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
    print("VoxOS: nie wczytano host.lua: " .. tostring(err))
end
