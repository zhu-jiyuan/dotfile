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
                contrast = "",  -- can be "hard", "soft" or empty string
                palette_overrides = {},
                overrides = {},
                dim_inactive = false,
                transparent_mode = true,
            })
            vim.cmd("colorscheme gruvbox")
        end,
        opts = ...,
    },
    -- bottom line
    -- {
    -- 	"nvim-lualine/lualine.nvim",
    -- 	-- opts = { theme = 'gruvbox-material'},
    -- 	config = function()
    -- 		require("lualine").setup({
    -- 			options = { theme = "gruvbox-material" },
    -- 		})
    -- 	end,
    -- },
    -- top line
    {
        "utilyre/barbecue.nvim",
        name = "barbecue",
        event = "VeryLazy",
        version = "*",
        dependencies = {
            "SmiteshP/nvim-navic",
            "nvim-tree/nvim-web-devicons", -- optional dependency
        },
        opts = {
            -- configurations go here
        },
    },
    -- blanklins
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        event = "VeryLazy",
        opts = {},
        --     config = function()
        --         local highlight = {
        --             "RainbowRed",
        --             "RainbowYellow",
        --             "RainbowBlue",
        --             "RainbowOrange",
        --             "RainbowGreen",
        --             "RainbowViolet",
        --             "RainbowCyan",
        --         }
        --
        --         local hooks = require "ibl.hooks"
        --         -- create the highlight groups in the highlight setup hook, so they are reset
        --         -- every time the colorscheme changes
        --         hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
        --             vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
        --             vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
        --             vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
        --             vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
        --             vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
        --             vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
        --             vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
        --         end)
        --
        --         require("ibl").setup { indent = { highlight = highlight } }
        --     end
        -- },
    }
}
