local disable_filetypes = { c = true, cpp = true }

return {
	{
		"stevearc/conform.nvim",
		opts = {},
		config = function()
			require("conform").setup({
				formatters_by_ft = {
					lua = { "stylua" },
					-- Conform will run multiple formatters sequentially
					python = { "isort", "black" },
					-- Use a sub-list to run only the first available formatter
					javascript = { { "prettierd", "prettier" } },
				},
				format_on_save = function(bufnr)
                    if disable_filetypes[vim.bo[bufnr].filetype] then
                        return
                    end
					return {
						timeout_ms = 500,
						lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
					}
				end,
			})
		end,
	},
}
