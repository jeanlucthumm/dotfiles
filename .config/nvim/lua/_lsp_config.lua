local lsp_installer = require 'nvim-lsp-installer';

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

lsp_installer.on_server_ready(function(server)
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities.textDocument.completion.completionItem.snippetSupport = true
    -- Injec nvim-cmp stuff
    require'cmp_nvim_lsp'.update_capabilities(capabilities)
    local config = {
        capabilities = capabilities,
        on_attach = require'common'.on_attach
    }

    if server.name == 'sumneko_lua' then config.settings = lua_config end

    server:setup(config);
end)
