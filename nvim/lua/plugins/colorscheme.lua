-- folke theme.
-- return {
--     {
--         "folke/tokyonight.nvim",
--         lazy = false,
--         priority = 1000,
--         opts = {},
--         config = function ()
--             vim.cmd[[colorscheme tokyonight]]
--         end
--     }
--
-- 


return {
    -- theme
    {
        "ellisonleao/gruvbox.nvim",
        priority = 1000,
        config = function()
            require("gruvbox").setup({
                terminal_colors = true, -- add neovim terminal colors
                undercurl = true,
                underline = true,
                bold = true,
                italic = {
                    strings = true,
                    emphasis = true,
                    comments = true,
                    operators = false,
                    folds = true,
                },
                strikethrough = true,
                invert_selection = false,
                invert_signs = false,
                invert_tabline = false,
                invert_intend_guides = false,
                inverse = true, -- invert background for search, diffs, statuslines and errors
                contrast = "", -- can be "hard", "soft" or empty string
                palette_overrides = {},
                overrides = {},
                dim_inactive = false,
                transparent_mode = false,
            })
            vim.cmd("colorscheme gruvbox")
        end,
        opts = ...
    },
    -- bottom line
    {
        'nvim-lualine/lualine.nvim',
        config = function()
            require('lualine').setup({})
        end
    },
    -- top line
    {
        "utilyre/barbecue.nvim",
        name = "barbecue",
        version = "*",
        dependencies = {
            "SmiteshP/nvim-navic",
            "nvim-tree/nvim-web-devicons", -- optional dependency
        },
        opts = {
            -- configurations go here
        },
    },
    -- tab line
    -- {
    --     "akinsho/bufferline.nvim",
    --     config = true
    -- },
    -- blankline
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        opts = {}
    }

}
