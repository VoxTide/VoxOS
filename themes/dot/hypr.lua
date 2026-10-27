-- VoxOS - motyw "dot": monochromatyczny, czarno-biały z czerwonym akcentem
hl.config({
    general = {
        gaps_in     = 6,
        gaps_out    = 12,
        border_size = 2,
        col = {
            active_border   = "rgba(edededff)",   -- biel
            inactive_border = "rgba(1f1f1fff)",   -- grafit
        },
    },

    decoration = {
        rounding = 18,
        shadow = {
            enabled      = true,
            range        = 14,
            render_power = 3,
            color        = "rgba(000000cc)",
        },
        blur = {
            enabled = true,
            size    = 6,
            passes  = 2,
        },
    },
})

-- Rozmycie pod launcherem i powiadomieniami (pasek jest czarny, bez rozmycia)
hl.layer_rule({ name = "blur-rofi", match = { namespace = "^rofi$" },          blur = true })
hl.layer_rule({ name = "blur-mako", match = { namespace = "^notifications$" }, blur = true })
