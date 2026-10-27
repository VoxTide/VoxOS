-- Ustawienia Hyprlanda tylko dla EliteBooka 1030 G1

-- Skala interfejsu: suwak w panelu szybkich ustawień (voxos-panel) zapisuje ją w ~/.config/voxos/scale.
-- Brak pliku = Hyprland dobiera skalę sam.
local scale = "auto"
local f = io.open((os.getenv("HOME") or "") .. "/.config/voxos/scale", "r")
if f then
    local v = f:read("l")
    f:close()
    if v and tonumber(v) then
        scale = v
    end
end

-- Wbudowany ekran: najlepsza rozdzielczość
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = scale,
})

-- Touchpad
hl.config({
    input = {
        touchpad = {
            tap_to_click         = true,
            disable_while_typing = true,
        },
    },
})

-- Klawisze jasności z okienkiem OSD (z powtarzaniem, działają też na zablokowanym ekranie)
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("bash ~/.local/bin/voxos-osd brightness up"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("bash ~/.local/bin/voxos-osd brightness down"), { locked = true, repeating = true })

-- Sprzętowe dekodowanie wideo na Intel HD 515 (Firefox, mpv): sterownik iHD z intel-media-driver
hl.env("LIBVA_DRIVER_NAME", "iHD")
