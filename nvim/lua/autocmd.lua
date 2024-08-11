-- vim.api.nvim_create_autocmd("BufWritePre", {
-- 	pattern = "*",
-- 	callback = function(args)
-- 		require("conform").format({ bufnr = args.buf })
-- 	end,
-- })
--
-- highlight on yank
local setting = require "settings"
local option = setting.option

vim.api.nvim_create_autocmd("TextYankPost", {
    callback = function()
        vim.highlight.on_yank()
    end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
    callback = function()
        vim.defer_fn(function()
            option.foldexpr = "nvim_treesitter#foldexpr()"
            option.foldmethod = "expr"
            option.foldcolumn = "1"
            -- opt.foldtext = ""

            option.foldnestmax = 3
            option.foldlevel = 99
            option.foldlevelstart = 99
        end, 150)
    end,
})
