---- Aliases
local opt = vim.opt
local g = vim.g
local api = vim.api
local env = vim.env
local fn = vim.fn

---- Plugins
require "paq" {
    "savq/paq-nvim",

    -- LSP & DAP
    "neovim/nvim-lspconfig",
    "kabouzeid/nvim-lspinstall",
    "mfussenegger/nvim-dap",
    "rcarriga/nvim-dap-ui",
    "hrsh7th/nvim-compe",

    -- Theme
    "kyazdani42/nvim-web-devicons",
    "jeanlucthumm/vim-solarized8",
    "morhetz/gruvbox",
    "sheerun/vim-polyglot",

    -- UI
    {"junegunn/fzf", run = function() fn["fzf#install"]() end},
    "junegunn/fzf.vim",
    "kyazdani42/nvim-tree.lua",
    "vim-airline/vim-airline",
    "vim-airline/vim-airline-themes",
    {"iamcco/markdown-preview.nvim", run = "cd app && yarn install"},
    "airblade/vim-gitgutter",

    -- Editor
    "tpope/vim-commentary",
    "tpope/vim-fugitive",
    "tpope/vim-dispatch",
    "jiangmiao/auto-pairs",
    "moll/vim-bbye",
    "andrejlevkovitch/vim-lua-format",
    "pseewald/vim-anyfold",

    -- Functional
    "MattesGroeger/vim-bookmarks",
    "neomake/neomake",
    "vim-test/vim-test",
    "907th/vim-auto-save"
}

---- Plugin configuration
-- LSP keybindings
g.mapleader = " "; -- sets <Leader> to <space>
local function on_attach(client, bufnr)
    -- Sets up LSP keybindings when LSP attaches to the buffer
    local function bnmap(lhs, rhs, ...)
        api.nvim_buf_set_keymap(bufnr, "n", lhs, "<Cmd>lua " .. rhs .. "<CR>",
                                ...)
    end

    api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

    -- Mappings
    local opts = {noremap = true, silent = true}
    bnmap("gd", "vim.lsp.buf.definition()", opts)
    bnmap("gr", "vim.lsp.buf.references()", opts)
    bnmap("K", "vim.lsp.buf.hover()", opts)
    bnmap("<Leader>r", "vim.lsp.buf.rename()", opts)
    bnmap("<Leader>ks", "vim.lsp.buf.signature_help()", opts)
    bnmap("<Leader>kl", "vim.lsp.diagnostic.show_line_diagnostic()", opts)
    bnmap("<Leader>kp", "vim.lsp.diagnostic.goto_prev()", opts)
    bnmap("<Leader>kn", "vim.lsp.diagnostic.goto_next()", opts)

    -- Capability specific commands
    if client.resolved_capabilities.document_highlight then
        -- Highlight symbol in document on hover. Delay is controlled by |updatetime|
        api.nvim_exec([[
      augroup lsp_document_highlight
      autocmd! * <buffer>
      autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
      autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
      augroup END
      ]], false)
    end
    if client.resolved_capabilities.document_format then
        bnmap("<Leader>f", "vim.lsp.buf.formatting()", opts)
    end
    if client.resolved_capabilities.code_lens then
        -- CodeLens provides extra actions like "Run Test"
        -- under lang specific unit tests
        bnmap("<F11>", "vim.lsp.codelens.run()", opts)
    end
end

-- LSP Lua config
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

-- LSP global setup
local function setup_lsp_servers()
    -- Call setup on every installed server
    require'lspinstall'.setup()

    local servers = require'lspinstall'.installed_servers()
    for _, server in pairs(servers) do
        local capabilities = vim.lsp.protocol.make_client_capabilities()
        capabilities.textDocument.completion.completionItem.snippetSupport =
            true
        local config = {capabilities = capabilities, on_attach = on_attach}

        -- Language specific config
        if server == "lua" then config.settings = lua_config end

        require"lspconfig"[server].setup(config)
    end
end
setup_lsp_servers()
require'lspinstall'.post_install_hook = function()
    -- Automatically reloads after :LspInstall
    setup_lsp_servers()
    vim.cmd("bufdo e") -- triggers FileType autocmd to start server
end

-- Compe provides autocompletion
require"compe".setup {
    enabled = true,
    autocomplete = true,
    source = {
        path = true,
        buffer = true,
        nvim_lsp = true,
        nvim_lua = true,
        calc = true,
        spell = true
    }
}

---- Neovim options
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.number = true
opt.termguicolors = true
opt.splitright = true
opt.hidden = true
opt.mouse = "a"
opt.updatetime = 500
opt.guifont = "Fira_Code_Retina_Nerd_Font_Complete:h11"
opt.completeopt = "menuone,noselect"
if vim.fn.has("nvim-0.5.0") == 1 then opt.signcolumn = "number" end

---- Global options
g.neomake_open_list = 2
g.auto_save = 0
g.auto_save_events = {"InsertLeave", "TextChanged", "CursorHold"}
g.neovide_cursor_animation_length = 0.05
g.bookmark_no_default_key_mappings = 1
vim.v["test#strategy"] = "neomake"

---- Keymap
local function map(mode, lhs, rhs, opts)
    local options = {noremap = true}
    if opts then options = vim.tbl_extend("force", options, opts) end
    api.nvim_set_keymap(mode, lhs, rhs, options)
end
local function nmap(...) map("n", ...) end
local function imap(...) map("i", ...) end

-- g
nmap("gt", ":tabe<CR>:term<CR>i")
-- <Leader>
nmap("<Leader>q", ":q<CR>")
-- nmap("<Leader>o", ":CocFzfList outline<CR>")
-- nmap("<Leader>O", ":CocFzfList symbols<CR>")
-- nmap("<Leader>d", ":CocFzfList diagnostics<CR>")
nmap("<Leader>q", ":qall<CR>")
nmap("<Leader><Leader>", ":write<CR>")
-- <Leader>v    nvim config
nmap("<Leader>ve", ":exe 'tabedit' stdpath('config').'/init.lua'<CR>")
nmap("<Leader>vs", ":exe 'source' stdpath('config').'/init.lua'<CR>")
-- <Leader>c    quickfix
nmap("<Leader>cl", ":cclose<CR>")
nmap("<Leader>cc", ":cc<CR>")
nmap("<Leader>co", ":copen<CR>")
-- <Leader>b    bookmarks
nmap("<Leader>bb", ":BookmarkToggle<CR>")
nmap("<Leader>ba", ":BookmarkAnnotate<CR>")
nmap("<Leader>bo", ":BookmarkShowAll<CR>")
-- <C-*>
nmap("<C-h>", ":tabp<CR>")
nmap("<C-l>", ":tabn<CR>")
map("t", "<C-h>", "<C-\\><C-n>:tabp<CR>")
map("t", "<C-l>", "<C-\\><C-l>:tabn<CR>")
map("t", "<C-w><C-w>", "<C-\\><C-l><C-w><C-w>")
nmap("<C-p>", ":Commands<CR>")
nmap("<C-e>", ":Buffers<CR>")
nmap("<C-A-e>", ":Files<CR>")
nmap("<A-1>", ":NERDTreeToggle")
nmap("<A-f>", ":NERDTreeFind")
-- <F*>
nmap("<F4>", ":Bdelete<CR>")
-- Auto completion
imap("<Tab>", "pumvisible() ? '<C-n>' : '<Tab>'", {expr = true})
imap("<S-Tab>", "pumvisible() ? '<C-p>' : '<S-Tab>'", {expr = true})
local cr_expr =
    "pumvisible() ? (empty(v:completed_item)?'<C-n>':'<C-g>u<CR>') : " ..
        "'<C-g>u<CR>'" -- <C-g>u starts a new item on 
imap("<CR>", cr_expr, {expr = true})

---- Theme
function SolarizedTheme()
    g.airline_theme = "solarized"
    -- Docstrings should be the same color as regular comments
    vim.cmd("hi! link rustCommentLineDoc Comment")
    vim.cmd("colorscheme solarized8")
end

function GruvboxTheme()
    g.gruvbox_italic = 1
    g.gruvbox_bold = 1
    g.airline_thee = "gruvbox"
    vim.v["$BAT_THEME"] = "gruvbox"
    vim.cmd("colorscheme gruvbox")
end

local function fallbackTheme()
    opt.background = "light"
    SolarizedTheme()
end

vim.cmd("hi! link pythonSpaceError Normal")

if env.TERM == "xterm-kitty" then
    if env.KITTY_THEME == "solarized-light" then
        opt.background = "light"
        SolarizedTheme()
    elseif env.KITTY_THEME == "solarized-dark" then
        opt.background = "dark"
        SolarizedTheme()
    else
        fallbackTheme()
    end
else
    fallbackTheme()
end

-- Filetype overrides
if vim.bo.filetype == "lua" then nmap("<Leader>f", "<Cmd> call LuaFormat()<CR>") end

---- Commands
