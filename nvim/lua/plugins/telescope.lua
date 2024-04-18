return {
    {
        cmd = "Telescope",
        event = 'VimEnter',
        "nvim-telescope/telescope.nvim",
        tag = '0.1.4',
        dependencies = {
            'nvim-lua/plenary.nvim',
            {
                'nvim-telescope/telescope-fzf-native.nvim',
                build = 'make'
            },
            { 'nvim-telescope/telescope-ui-select.nvim' },

            -- Useful for getting pretty icons, but requires a Nerd Font.
            { 'nvim-tree/nvim-web-devicons',            enabled = vim.g.have_nerd_font },
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
                    },
                    ['ui-select'] = {
                        require('telescope.themes').get_dropdown(),
                    },
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
            pcall(require('telescope').load_extension, 'fzf')
            pcall(require('telescope').load_extension, 'ui-select')

            -- See `:help telescope.builtin`
            local builtin = require 'telescope.builtin'

            -- Slightly advanced example of overriding default behavior and theme
            vim.keymap.set('n', '<leader>/', function()
                -- You can pass additional configuration to Telescope to change the theme, layout, etc.
                builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
                    winblend = 10,
                    previewer = false,
                })
            end, { desc = '[/] Fuzzily search in current buffer' })

            -- It's also possible to pass additional configuration options.
            --  See `:help telescope.builtin.live_grep()` for information about particular keys
            vim.keymap.set('n', '<leader>s/', function()
                builtin.live_grep {
                    grep_open_files = true,
                    prompt_title = 'Live Grep in Open Files',
                }
            end, { desc = '[S]earch [/] in Open Files' })

        end
    },

}
