-- Ustawienia Hyprlanda tylko dla EliteBooka 1030 G1

-- Wbudowany ekran: najlepsza rozdzielczość, skalowanie dobierane automatycznie
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
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
