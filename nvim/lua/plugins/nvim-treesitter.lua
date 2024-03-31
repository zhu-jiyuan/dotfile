local limit_tbl = {
    lua = {
        max_line = 5000,
        max_size = 1024 * 1024 * 5, -- 5Mb
    }
}

local function is_disabled(lang, bufnr)
    local limit_lang = limit_tbl[lang]
    if not limit_lang then
        return false
    end
    local line = vim.api.nvim_buf_line_count(bufnr)
    local name = vim.api.nvim_buf_get_name(bufnr)
    -- count bufnr size
    local size = vim.fn.getfsize(name)
    -- print("lang====>", lang, "line====>", line, "size====>", size)

    if limit_lang.max_line < line then
        return true
    end

    if limit_lang.max_size < size then
        return true
    end

    return false
end


return {
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        event = "VeryLazy",
        config = function()
            local configs = require("nvim-treesitter.configs")

            configs.setup({
                ensure_installed = {
                    "c",
                    "lua",
                    "vim",
                    "vimdoc",
                    "json",
                    "cpp",
                    "python",
                    "markdown",
                    "markdown_inline",
                },
                ignore_install = {},
                sync_install = false,
                highlight = {
                    enable = true,
                    disable = is_disabled,
                    additional_vim_regex_highlighting = false,
                },
                indent = { enable = true },
            })
        end
    }
}
