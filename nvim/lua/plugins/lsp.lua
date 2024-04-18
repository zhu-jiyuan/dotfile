local server_list = {
    lua_ls = {
        settings = {
            lua = {

            }
        }
    },
    pyright = {},
    jsonls = {},
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
            desc = 'LSP: ' .. desc
        end

        vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
    end

    nmap('<leader>rn', "<cmd>Lspsaga rename ++project<CR>", '[R]e[n]ame')
    nmap('<leader>ca', "<cmd>Lspsaga code_action<CR>", '[C]ode [A]ction')

    nmap('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
    nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
    nmap('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
    nmap('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
    nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
    nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

    -- See `:help K` for why this keymap
    nmap('K',"<cmd>Lspsaga hover_doc<CR>" , 'Hover Documentation')
    nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

    -- Lesser used LSP functionality
    nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
    nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
    nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
    nmap('<leader>wl', function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, '[W]orkspace [L]ist Folders')

    -- Create a command `:Format` local to the LSP buffer
    nmap('<leader>fm', function()
        vim.lsp.buf.format({
            async = true,
        })
    end, 'Format current buffer with LSP')
    -- lsp diagnostics
    nmap('<leader>da', require('telescope.builtin').diagnostics, 'lsp diagnosticls')
end

return {
    {
        event = "VeryLazy",
        'neovim/nvim-lspconfig',
        dependencies = {
            { "folke/neodev.nvim",  opts = {} },
            { "folke/neoconf.nvim", cmd = "Neoconf", config = false, dependencies = { "nvim-lspconfig" } },
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            'WhoIsSethDaniel/mason-tool-installer.nvim',
            'nvimdev/lspsaga.nvim',
        },
        config = function()
            require("neoconf").setup({
                -- override any of the default settings here
            })
            require "neodev".setup()
            require "lspsaga".setup()

            require("mason").setup({
                ui = {
                    icons = {
                        package_installed = "✓",
                        package_pending = "➜",
                        package_uninstalled = "✗"
                    }
                }
            })


            require("mason-lspconfig").setup({
                ensure_installed = vim.tbl_keys(server_list),
            })
            local capabilities = require "cmp_nvim_lsp".default_capabilities()

            for server, server_config in pairs(server_list) do
                require("lspconfig")[server].setup(
                    vim.tbl_deep_extend("keep", {
                        capabilities = capabilities,
                        on_attach = on_attach,
                        settings = server_list[server],
                        filetypes = (server_list[server] or {}).filetypes,
                    }, server_config)
                )
            end
        end
    }


}
