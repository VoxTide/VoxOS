-- VoxOS - motyw Nord: wygląd okien Hyprlanda (https://www.nordtheme.com)
hl.config({
    general = {
        gaps_in     = 4,
        gaps_out    = 8,
        border_size = 2,
        col = {
            active_border   = { colors = { "rgba(88c0d0ee)", "rgba(81a1c1ee)" }, angle = 45 },  -- Nord Frost
            inactive_border = "rgba(4c566aaa)",                                                -- Nord 3
        },
    },

    decoration = {
        rounding = 10,
        shadow = {
            enabled      = true,
            range        = 8,
            render_power = 3,
            color        = "rgba(1a1d23aa)",
        },
        blur = {
            enabled = true,
            size    = 4,
            passes  = 2,
        },
    },
})

-- Rozmycie tła pod półprzezroczystym paskiem, launcherem i powiadomieniami
hl.layer_rule({ name = "blur-waybar", match = { namespace = "^waybar$" },        blur = true })
hl.layer_rule({ name = "blur-rofi",   match = { namespace = "^rofi$" },          blur = true })
hl.layer_rule({ name = "blur-mako",   match = { namespace = "^notifications$" }, blur = true })
