local lazy_status = require("lazy.status")
local custom = require("custom")


local function modified()
    if vim.bo.modified then
        return " "
    else
        return "󰄳 "
    end
end

local function readonly()
    if vim.bo.readonly then
        return " "
    else
        return ""
    end
end

local function recording()
    local reg = vim.fn.reg_recording()
    if reg ~= "" then
        return "recording @" .. reg
    end
    reg = vim.fn.reg_recorded()
    if reg ~= "" then
        return "recorded @" .. reg
    end

    return ""
end

local function get_lsp_text()
    local clients = vim.lsp.get_clients()
    local buf = vim.api.nvim_get_current_buf()
    clients = vim.iter(clients)
        :filter(function(client)
            return client.attached_buffers[buf]
        end)
        :filter(function(client)
            return client.name ~= "copilot"
        end)
        :map(function(client)
            return client.name
        end)
        :totable()
    local info = table.concat(clients, ", ")

    return info
end

-- local bufline = {
--     lualine_a = {
--         {
--             "buffers",
--             cond = function()
--                 return vim.bo.filetype ~= "alpha"
--             end,
--             mode = 2,
--             section_separators = { left = "", right = "" },
--             use_mode_colors = true,
--             filetype_names = {
--                 TelescopePrompt = " Telescope",
--                 fzf = " FZF",
--                 alpha = "󰏘 Alpha",
--                 minifiles = " Mini.Files",
--                 toggleterm = "ToggleTerm",
--                 checkhealth = "󰄳 Checkhelth",
--                 oil = " Oil",
--                 Outline = "󰇽 Outline",
--                 lazy = "󰜢 Lazy",
--                 Mundo = " Mundo",
--                 MundoDiff = " MundoDiff",
--                 CompetiTest = " CompetiTest",
--                 lspinfo = " LspInfo",
--             },
--             symbols = {
--                 modified = " ●",
--                 alternate_file = "",
--                 directory = "󰉋",
--             },
--         },
--     },
--     lualine_z = {},
-- }

local opts = {
    options = {
        icons_enabled = true,
        theme = "everforest",
        disabled_filetypes = {
            "alpha",
            "TelescopePrompt",
            "mason",
        },
        always_divide_middle = true,
        globalstatus = true,
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
    },
    sections = {
        lualine_a = {
            {
                modified,
                separator = { left = "", right = "" },
                padding = { left = 1, right = 0 },
            },
            {
                "mode",
                separator = { left = "", right = "" },
                padding = { left = 0, right = 0 },
            },
        },
        lualine_b = {
            {
                "branch",
                icon = "",
            },
        },
        lualine_c = {
            {
                "filetype",
                colored = true,
                icon_only = true,
                icon = { align = "left" },
                padding = { left = 1, right = 0 },
            },
            {
                'filename',
                file_status = false, -- Displays file status (readonly status, modified status)
                path = 1,            -- 0: Just the filename
                -- 1: Relative path
                -- 2: Absolute path
                -- 3: Absolute path, with tilde as the home directory
                -- 4: Filename and parent dir, with tilde as the home directory

                shorting_target = 40, -- Shortens path to leave 40 spaces in the window
                -- for other components. (terrible name, any suggestions?)
            },
            {
                "diagnostics",
                symbols = {
                    error = custom.symbol.error,
                    warn = custom.symbol.warn,
                    info = custom.symbol.info,
                    hint = custom.symbol.hint,
                },
            },
            readonly,
        },
        lualine_x = {
            {
                "diff",
                symbols = {
                    added = " ",
                    modified = " ",
                    removed = " ",
                },
            },
            {
                lazy_status.updates,
                cond = lazy_status.has_updates,
                color = { fg = "#ff9e64" },
            },
            recording,
            {
                get_lsp_text,
                "lsp_status",
                icon = ' LSP:',
                color = { fg = '#fff9e64', gui = 'bold' },
            },
        },
        lualine_y = {
            {
                "encoding",
                right_padding = 2,
            },
        },
        lualine_z = {
            {
                "location",
                padding = 0,
            },
            {
                function()
                    local cursorcol = vim.fn.virtcol(".")
                    if cursorcol >= 10 then
                        return " · "
                    else
                        return "· "
                    end
                end,
                padding = 0,
            },
            {
                "progress",
                -- separator = { right = "" },
                icon = { "󰇽", align = "left" },
                padding = { left = 0, right = 2 },
            },
        },
    },
    -- tabline = bufline,
    extensions = {
        "oil",
        "man",
        "quickfix",
        "neo-tree",
        "symbols-outline",
        "mason",
        "lazy",
        "trouble",
        "toggleterm",
        "fzf",
    },
}
return {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    init = function()
        vim.opt.laststatus = 0
    end,
    dependencies = {
        { "nvim-tree/nvim-web-devicons" },
        -- { "ofseed/copilot-status.nvim" },
    },
    config = function()
        require("lualine").setup(opts)
    end,
}
