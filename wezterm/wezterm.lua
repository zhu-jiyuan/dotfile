local wezterm = require 'wezterm'
local act = wezterm.action

local wsl_domains = wezterm.default_wsl_domains()

for i, domain in ipairs(wsl_domains) do
    domain.default_prog = { "zsh" }
end


local config = {
    font = wezterm.font("JetBrainsMono Nerd Font Mono"),
    font_size = 12.0,
    color_scheme = "Gruvbox Dark",

    window_decorations = "INTEGRATED_BUTTONS|RESIZE",

    -- tab bar
    enable_tab_bar = true,
    hide_tab_bar_if_only_one_tab = false,
    use_fancy_tab_bar = true,
    --tab_max_width = 25,
    show_tab_index_in_tab_bar = false,
    switch_to_last_active_tab_when_closing_tab = true,


    window_close_confirmation = "NeverPrompt",


    window_background_opacity = 0.95,
    macos_window_background_blur = 70,

    text_background_opacity = 0.98,
    adjust_window_size_when_changing_font_size = true,
    window_padding = {
        left = 5,
        right = 20,
        top = 12,
        bottom = 7,
    },
    keys = {
        { key = "v",      mods = "CTRL",       action = act { PasteFrom = "Clipboard" } },
        { key = "Insert", mods = "SHIFT",      action = act { PasteFrom = "Clipboard" } },
        { key = "Insert", mods = "CTRL",       action = act { PasteFrom = "PrimarySelection" } },
        { key = "Insert", mods = "CTRL|SHIFT", action = act { PasteFrom = "PrimarySelection" } },
        { key = '+',      mods = 'SHIFT|ALT',  action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
        { key = '_',      mods = 'SHIFT|ALT',  action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
        { key = 'Tab',    mods = 'SHIFT|CTRL', action = act.ActivateTabRelative(1) },
        { key = '+', mods = 'SHIFT|CTRL', action = act.IncreaseFontSize },
        { key = '_', mods = 'SHIFT|CTRL', action = act.DecreaseFontSize },
        { key = 'N', mods = 'SHIFT|CTRL', action = act.SpawnWindow },
        { key = 'T', mods = 'SHIFT|CTRL', action = act.ShowLauncher },
        { key = 'W', mods = 'SHIFT|CTRL', action = act.CloseCurrentTab{ confirm = false } },
    },
    default_domain = "WSL:Debian",
    wsl_domains = wsl_domains,


    animation_fps = 120,
    max_fps = 120,

    -- scrollbar
    enable_scroll_bar = true,

}


return config
