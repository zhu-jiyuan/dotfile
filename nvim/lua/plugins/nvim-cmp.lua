return {
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-buffer",
			{
				"zbirenbaum/copilot.lua",
				cmd = "Copilot",
				event = "InsertEnter",
				config = function()
					require("copilot").setup({
						suggestion = {
							enabled = true,
							auto_trigger = true,
							auto_refresh = true,
							debounce = 75,
							keymap = {
								accept_word = false,
								accept_line = false,
								next = "<M-]>",
								prev = "<M-[>",
							},
						},
					})
				end,
			},
			{
				"saadparwaiz1/cmp_luasnip",
				dependencies = {
					{
						"L3MON4D3/LuaSnip",
						dependencies = {
							"rafamadriz/friendly-snippets",
						},
					},
				},
			},
			"neovim/nvim-lspconfig",
		},
		config = function()
			require("luasnip.loaders.from_vscode").lazy_load()
			local copilot_suggestion = require("copilot.suggestion")
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			luasnip.config.setup({})
			-- Global setup.
			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body) -- For `luasnip` users.
					end,
				},
				window = {
					completion = cmp.config.window.bordered(),
					-- documentation = cmp.config.window.bordered(),
				},
				mapping = cmp.mapping.preset.insert({
					["<C-d>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-j>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior, count = 1 }),
					["<C-k>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior, count = 1 }),
					["<C-c>"] = function()
						cmp.mapping.close()
						vim.api.nvim_command("stopinsert")
					end,
					["<Tab>"] = cmp.mapping(function(fallback)
						-- This little snippet will confirm with tab, and if no entry is selected, will confirm the first item
						if cmp.visible() then
							local entry = cmp.get_selected_entry()
							if not entry then
								cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
							end
							cmp.confirm()
						else
							fallback()
						end
					end, { "i", "s", "c" }),

					["<CR>"] = cmp.mapping(function(fallback)
						if luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }),
					["<C-Space>"] = cmp.mapping(function(fallback)
						if copilot_suggestion.is_visible() then
							copilot_suggestion.accept()
						end
						fallback()
					end, { "i", "s", "c" }),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "buffer" },
					{ name = "path" },
					{ name = "luasnip" }, -- For luasnip users.
				}),
			})

			-- `/` cmdline setup.
			cmp.setup.cmdline("/", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "buffer" },
				},
			})

			-- `:` cmdline setup.
			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = "path" },
					{ name = "cmdline" },
				}),
			})
		end,
	},
}
