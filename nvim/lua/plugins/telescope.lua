return {
    {
        cmd = "Telescope",
        "nvim-telescope/telescope.nvim",
        tag = '0.1.4',
        dependencies = {
            'nvim-lua/plenary.nvim',
            {
                'nvim-telescope/telescope-fzf-native.nvim',
                build = 'make'
            }
        },
        keys = {
            { "<leader>ff", ":Telescope find_files<CR>", desc = "find files" },
            { "<leader>fg", ":Telescope live_grep<CR>",  desc = "grep file" },
            { "<leader>fr", ":Telescope resume<CR>",     desc = "resume" },
            { "<leader>fo", ":Telescope oldfiles<CR>",   desc = "oldfiles" },
            { "<leader>fb", ":Telescope buffers<CR>",    desc = "buffers" },
            { "<leader>fh", ":Telescope help_tags<CR>",  desc = "help_tags" },
        },
        config = function()
            require('telescope').setup {
                extensions = {
                    fzf = {
                        fuzzy = true,                   -- false will only do exact matching
                        override_generic_sorter = true, -- override the generic sorter
                        override_file_sorter = true,    -- override the file sorter
                        case_mode = "smart_case",       -- or "ignore_case" or "respect_case"
                        -- the default case_mode is "smart_case"
                    }
                },
                defaults = {
                    file_ignore_patterns = {
                        '.git',
                        'lazy-lock.json',
                        '*-lock.yaml',
                        'node_modules',
                        '%.lock',
                    },
                    dynamic_preview_title = true,
                    path_display = { 'smart' },
                },
                pickers = {
                    find_files = {
                        hidden = true,
                    },
                },
            }
            require('telescope').load_extension('fzf')
        end
    },

}
