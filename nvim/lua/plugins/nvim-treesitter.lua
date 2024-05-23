return {
	{
		"nvim-treesitter/nvim-treesitter",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		build = ":TSUpdate",
		-- event = "VeryLazy",
		config = function()
			local configs = require("nvim-treesitter.configs")

			configs.setup({
				ensure_installed = {
					"c",
					"lua",
					"vimdoc",
					"json",
					"python",
					"markdown",
					"bash",
				},
				ignore_install = {},
				sync_install = false,
				auto_install = true,
				highlight = {
					enable = true,
					disable = function(lang, buf)
						local max_filesize = 100 * 1024 -- 100 KB
						local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
						if ok and stats and stats.size > max_filesize then
							return true
						end
					end,
					additional_vim_regex_highlighting = { "markdown" },
				},
				indent = { enable = true },
				textobjects = {
					select = {
						enable = true,
						lookahead = true,
						keymaps = {
							["af"] = "@function.outer",
							["if"] = "@function.inner",
							-- ["ac"] = "@class.outer",
							-- ["ic"] = { query = "@class.inner", desc = "Select inner part of a class region" },
							-- ["as"] = { query = "@scope", query_group = "locals", desc = "Select language scope" },
						},
						-- selection_modes = {
						-- 	["@parameter.outer"] = "v", -- charwise
						-- 	["@function.outer"] = "V", -- linewise
						-- 	["@class.outer"] = "<c-q>", -- blockwise
						-- },
						include_surrounding_whitespace = true,
					},
				},
			})
		end,
	},
	{

		"nvim-treesitter/nvim-treesitter-context",
		event = "VeryLazy",
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			require("treesitter-context").setup({
				enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
				max_lines = 2, -- How many lines the window should span. Values <= 0 mean no limit.
				min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
				line_numbers = true,
				multiline_threshold = 10, -- Maximum number of lines to show for a single context
				trim_scope = "outer", -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
				mode = "topline", -- Line used to calculate context. Choices: 'cursor', 'topline'
				-- Separator between context and content. Should be a single character string, like '-'.
				-- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
				separator = nil,
				zindex = 10, -- The Z-index of the context window
				on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
			})
		end,
	},
}
