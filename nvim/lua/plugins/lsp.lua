local custom = require("custom")

local server_list = {
    lua_ls = {
        settings = {
            lua = {},
        },
    },
    pyright = {},
    jsonls = {},
    gopls = {},
    clangd = {},
}

local on_attach = function(_, bufnr)
    -- NOTE: Remember that lua is a real programming language, and as such it is possible
    -- to define small helper and utility functions so you don't have to repeat yourself
    -- many times.
    --
    -- In this case, we create a function that lets us more easily define mappings specific
    -- for LSP related items. It sets the mode, buffer and description for us each time.
    local nmap = function(keys, func, desc)
        if desc then
            desc = "LSP: " .. desc
    end
    vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc })
    end

    -- nmap("<leader>rn", function()
    -- 	vim.lsp.buf.rename()
    -- end, "[R]e[n]ame")
    -- nmap("<leader>ca", function()
    -- 	vim.lsp.buf.code_action()
    -- end, "[C]ode [A]ction")

    nmap("<leader>rn", "<cmd>Lspsaga rename ++project<cr>", "Rename")
    nmap("<leader>ca", "<cmd>Lspsaga code_action<CR>", "Code Action")
    nmap("<leader>ot", "<cmd>Lspsaga outline<CR>", "OutLine")

    local fzf_lua = require("fzf-lua")
    nmap("gd", fzf_lua.lsp_definitions, "[G]oto [D]efinition")
    nmap("gr", fzf_lua.lsp_references, "[G]oto [R]eferences")
    nmap("gI", fzf_lua.lsp_implementations, "[G]oto [I]mplementation")
    nmap("<leader>D", fzf_lua.lsp_typedefs, "Type [D]efinition")
    nmap("<leader>ds", fzf_lua.lsp_document_symbols, "[D]ocument [S]ymbols")
    nmap("<leader>ws", fzf_lua.lsp_live_workspace_symbols, "[W]orkspace [S]ymbols")

    -- See `:help K` for why this keymap
    -- nmap("K", function()
    -- 	vim.lsp.buf.hover()
    -- end, "Hover Documentation")
    nmap("<leader>K", "<cmd>Lspsaga hover_doc<CR>", "Hover Documentation")
    nmap("<leader>pd", "<cmd>Lspsaga peek_definition<CR>", "Peek Definition")

    nmap("<leader>H", vim.lsp.buf.signature_help, "Signature Documentation")

    -- Lesser used LSP functionality
    nmap("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
    nmap("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
    nmap("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
    nmap("<leader>wl", function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, "[W]orkspace [L]ist Folders")

    -- Create a command `:Format` local to the LSP buffer
    nmap("<leader>fm", function()
        require("conform").format({ async = true, lsp_fallback = true })
    end, "Format current buffer")

    -- lsp diagnostics
    nmap("<leader>da", fzf_lua.lsp_workspace_diagnostics, "lsp diagnosticls")

    require("lspsaga").setup({
        outline = {
            keys = {
                quit = "<C-c>",
                toggle_or_jump = "<cr>",
            },
        },
        finder = {
            keys = {
                quit = "<C-c>",
                edit = "<C-o>",
                toggle_or_open = "<cr>",
            },
        },
        definition = {
            keys = {
                edit = "<C-o>",
                vsplit = "<C-v>",
            },
        },
        code_action = {
            keys = {
                quit = "<C-c>",
            },
        },
        ui = {
            code_action = "🔅",
        },
        lightbulb = {
            enable = true,
            sign = true,
            debounce = 10,
            sign_priority = 1,
            virtual_text = false,
            -- enable_in_insert = true,
        },
        hover = {
            keys = {
                quit = "<C-c>",
            },
        },
        rename= {
            keys = {
                quit = "<C-c>",
            },
        },
    })
    vim.diagnostic.config({
        signs = {
            text = {
                [vim.diagnostic.severity.ERROR] = custom.symbol.error,
                [vim.diagnostic.severity.WARN] = custom.symbol.warn,
                [vim.diagnostic.severity.INFO] = custom.symbol.info,
                [vim.diagnostic.severity.HINT] = custom.symbol.hint,
            },
        },
    })
end

return {
    {
        "neovim/nvim-lspconfig",
        event = "VeryLazy",
        dependencies = {
            { "folke/neodev.nvim",  opts = {} },
            { "folke/neoconf.nvim", cmd = "Neoconf", config = false, dependencies = { "nvim-lspconfig" } },
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "WhoIsSethDaniel/mason-tool-installer.nvim",
            "nvimdev/lspsaga.nvim",
        },
        -- opts = {
        -- 	autoformat = false,
        -- },
        config = function()
            require("neoconf").setup({
                -- override any of the default settings here
            })
            require("neodev").setup()
            -- require "lspsaga".setup()

            require("mason").setup({
                ui = {
                    icons = {
                        package_installed = "✓",
                        package_pending = "➜",
                        package_uninstalled = "✗",
                    },
                },
            })

            require("mason-lspconfig").setup({
                ensure_installed = vim.tbl_keys(server_list),
            })
            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            for server, server_config in pairs(server_list) do
                require("lspconfig")[server].setup(vim.tbl_deep_extend("keep", {
                    capabilities = capabilities,
                    on_attach = on_attach,
                    settings = server_list[server],
                    filetypes = (server_list[server] or {}).filetypes,
                }, server_config))
            end
        end,
    },
}
