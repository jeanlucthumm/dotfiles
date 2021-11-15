local lua_config = {
    Lua = {
        runtime = {
            -- LuaJIT in the case of Neovim
            version = 'LuaJIT',
            path = vim.split(package.path, ';')
        },
        diagnostics = {
            -- Get the language server to recognize the `vim` global
            globals = {'vim'}
        },
        workspace = {
            -- Make the server aware of Neovim runtime files
            library = {
                [vim.fn.expand('$VIMRUNTIME/lua')] = true,
                [vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true
            }
        }
    }
}
local function setup_lsp_servers()
    -- Call setup on every installed server
    require'lspinstall'.setup()

    local servers = require'lspinstall'.installed_servers()
    for _, server in pairs(servers) do
        local capabilities = vim.lsp.protocol.make_client_capabilities()
        capabilities.textDocument.completion.completionItem.snippetSupport =
            true
        -- Inject nvim-cmp stuff
        require'cmp_nvim_lsp'.update_capabilities(capabilities)
        local config = {
            capabilities = capabilities,
            on_attach = require'common'.on_attach
        }

        -- Language specific config
        if server == "lua" then config.settings = lua_config end
        if server == "dartls" then goto continue end -- set up by flutter

        require'lspconfig'[server].setup(config)
        ::continue::
    end
end
setup_lsp_servers()
require'lspinstall'.post_install_hook = function()
    -- Automatically reloads after :LspInstall
    setup_lsp_servers()
    vim.cmd('bufdo e') -- triggers FileType autocmd to start server
end
