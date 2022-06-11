local lsp_installer = require 'nvim-lsp-installer';

-- All paths here will be registered with the Lua LSP
local lua_library = {}

local function add(lib)
    for _, p in pairs(vim.fn.expand(lib, false, true)) do
        p = vim.loop.fs_realpath(p)
        lua_library[p] = true
    end
end

-- Lua libraries include nvim config directory, vim api,
-- but also every installed plugin with packer which gives
-- auto complete for their configuration
add("$VIMRUNTIME")
add("~/.config/nvim")
add("~/.local/share/nvim/site/pack/packer/opt/*")
add("~/.local/share/nvim/site/pack/packer/start/*")

local lua_config = {
    Lua = {
        runtime = {
            version = 'LuaJIT',
            path = {vim.split(package.path, ';'), "lua/?.lua", "lua/?/init.lua"}
        },
        diagnostics = {
            -- Get the language server to recognize the `vim` global
            globals = {'vim'}
        },
        workspace = {
            library = lua_library,
            maxPreload = 2000,
            preloadFileSize = 50000
        },
        telemetry = {enable = false}
    }
}

-- TODO: this is now deprecated!
-- `on_server_ready` is called for every LSP server installed with LSP installer
-- Server specific configuration can be found in `:help lspconfig-server-configurations`
lsp_installer.on_server_ready(function(server)
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities.textDocument.completion.completionItem.snippetSupport = true
    -- Inject nvim-cmp stuff
    require'cmp_nvim_lsp'.update_capabilities(capabilities)
    local config = {
        capabilities = capabilities,
        on_attach = require'common'.on_attach
    }

    if server.name == 'sumneko_lua' then config.settings = lua_config end

    server:setup(config);
end)
