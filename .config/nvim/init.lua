---- Aliases
local opt = vim.opt
local g = vim.g
local api = vim.api
local env = vim.env
local fn = vim.fn
local cmd = vim.cmd

---- Plugins
require "paq" {
    "savq/paq-nvim",

    -- LSP & DAP & nvim
    "neovim/nvim-lspconfig",
    "kabouzeid/nvim-lspinstall",
    "mfussenegger/nvim-dap",
    "rcarriga/nvim-dap-ui",
    "hrsh7th/nvim-compe",
    {"nvim-treesitter/nvim-treesitter", run = function() cmd("TSUpdate") end},
    "glepnir/lspsaga.nvim",
    "theHamsta/nvim-dap-virtual-text",

    -- Theme
    "kyazdani42/nvim-web-devicons",
    "jeanlucthumm/vim-solarized8",
    "morhetz/gruvbox",
    "marko-cerovac/material.nvim",

    -- UI
    {"junegunn/fzf", run = function() fn["fzf#install"]() end},
    "junegunn/fzf.vim",
    "ojroques/nvim-lspfuzzy",
    "kyazdani42/nvim-tree.lua",
    {"iamcco/markdown-preview.nvim", run = "cd app && yarn install"},
    "airblade/vim-gitgutter",
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "simrat39/symbols-outline.nvim",
    "tom-anders/telescope-vim-bookmarks.nvim",
    "simrat39/symbols-outline.nvim",
    "hoob3rt/lualine.nvim",
    "akinsho/nvim-bufferline.lua",

    -- Editor
    "tpope/vim-commentary",
    "tpope/vim-fugitive",
    "tpope/vim-dispatch",
    "jiangmiao/auto-pairs",
    "moll/vim-bbye",
    "andrejlevkovitch/vim-lua-format",
    "pseewald/vim-anyfold",
    "onsails/lspkind-nvim",

    -- Functional
    "MattesGroeger/vim-bookmarks",
    "neomake/neomake",
    "vim-test/vim-test",
    "907th/vim-auto-save"
}

---- Global options
g.neomake_open_list = 2
g.auto_save = 0
g.auto_save_events = {"InsertLeave", "TextChanged", "CursorHold"}
g.neovide_cursor_animation_length = 0.05
g.bookmark_no_default_key_mappings = 1
g.symbols_outline = {show_symbol_details = false}
g.mapleader = " " -- sets <Leader> to <space>
g.dap_virtual_text = true
vim.v["test#strategy"] = "neomake"

---- Plugin configuration
-- LSP keybindings
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

-- DAP Config
local dap = require "dap"
dap.adapters.lldb = {
    type = "executable",
    command = "/usr/bin/lldb-vscode",
    name = "lldb"
}
dap.configurations.cpp = {
    {
        name = "Launch",
        type = "lldb",
        request = "launch",
        program = function()
            return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/',
                                'file')
        end,
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
        args = {},

        -- if you change `runInTerminal` to true, you might need to change the yama/ptrace_scope setting:
        --
        --    echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
        --
        -- Otherwise you might get the following error:
        --
        --    Error on launch: Failed to attach to the target process
        --
        -- But you should be aware of the implications:
        -- https://www.kernel.org/doc/html/latest/admin-guide/LSM/Yama.html
        runInTerminal = false
    }
}
-- TODO: continue() supports multiple configs, it just prompts
dap.configurations.rust = {
    {
        name = "Launch Debug",
        type = "lldb",
        request = "launch",
        program = '${workspaceFolder}/target/debug/${workspaceFolderBasename}',
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
        args = {},
        runInTerminal = false
    }
}

fn.sign_define('DapBreakpoint',
               {text = '🛑', texthl = '', linehl = '', numhl = ''})

-- Smaller plugin setup
require"dapui".setup {}
require"compe".setup {
    enabled = true,
    autocomplete = true,
    source = {
        path = true,
        buffer = true,
        nvim_lsp = true,
        nvim_lua = true,
        calc = true
    }
}
require"nvim-treesitter.configs".setup {
    ensure_installed = "maintained",
    highlight = {enable = true}
}
require"lspfuzzy".setup {}
require"lspkind".init {}
require"telescope".setup {
    defaults = {
        mappings = {
            i = {
                ["<C-k>"] = "move_selection_previous",
                ["<C-j>"] = "move_selection_next"
            },
            n = {["<C-c>"] = "close"}
        }
    }
}
require"telescope".load_extension("vim_bookmarks")
require"lualine".setup {
    options = {theme = "material-nvim", extensions = {"quickfix", "nvim-tree"}}
}
require"bufferline".setup {
    options = {
        tab_size = 20,
        separator_style = "slant",
        offsets = {
            {
                filetype = "NvimTree",
                text = "File Explorer",
                highlight = "Directory",
                text_align = "left"
            }
        }

    }
}

---- Neovim options
opt.tabstop = 2
opt.shiftwidth = 2
opt.termguicolors = true
opt.expandtab = true
opt.number = true
opt.splitright = true
opt.hidden = true
opt.mouse = "a"
opt.updatetime = 500
opt.guifont = "Fira_Code_Retina_Nerd_Font_Complete:h11"
opt.completeopt = "menuone,noselect"
if vim.fn.has("nvim-0.5.0") == 1 then opt.signcolumn = "number" end

---- Keymap (note that some keys are defined in the LSP section)
local function map(mode, lhs, rhs, opts)
    local options = {noremap = true}
    if opts then options = vim.tbl_extend("force", options, opts) end
    api.nvim_set_keymap(mode, lhs, rhs, options)
end
local function nmap(...) map("n", ...) end
local function ncmap(lhs, rhs, ...) nmap(lhs, "<Cmd>" .. rhs .. "<CR>", ...) end
local function imap(...) map("i", ...) end

-- g
nmap("gt", ":tabe<CR>:term<CR>i")
-- <Leader>
ncmap("<Leader>q", "qall")
ncmap("<Leader>o", "Telescope lsp_document_symbols")
ncmap("<Leader>O", "Telescope dynamic_workspace_symbols")
ncmap("<Leader>d", "Telescope lsp_document_diagnostics")
ncmap("<Leader>D", "Telescope lsp_workspace_diagnostics")
ncmap("<Leader>s", "SymbolsOutline")
ncmap("<Leader><Leader>", "write")
-- <Leader>v    nvim config
ncmap("<Leader>ve", "exe 'tabedit' stdpath('config').'/init.lua'")
nmap("<Leader>vs", ":exe 'source' stdpath('config').'/init.lua'<CR>")
-- <Leader>c    quickfix
ncmap("<Leader>cl", "cclose")
ncmap("<Leader>cc", "cc")
ncmap("<Leader>co", "copen")
-- <Leader>b    bookmarks
ncmap("<Leader>bb", "BookmarkToggle")
ncmap("<Leader>ba", "BookmarkAnnotate")
ncmap("<Leader>bo", "Telescope vim_bookmarks all")
-- <C-*> and <A-*>
ncmap("<C-h>", "BufferLineCyclePrev")
ncmap("<C-l>", "BufferLineCycleNext")
map("t", "<C-h>", "<C-\\><C-n><Cmd>BufferLineCyclePrev<CR>")
map("t", "<C-l>", "<C-\\><C-l><Cmd><CR>")
map("t", "<C-w><C-w>", "<C-\\><C-l><C-w>BufferLineCycleNext<C-w>")
ncmap("<C-p>", "Telescope commands")
ncmap("<C-e>", "Buffers") -- regular fzf is faster
ncmap("<C-A-e>", "Telescope find_files")
ncmap("<A-1>", "NvimTreeToggle")
ncmap("<A-f>", "NvimTreeFindFile")
-- <F*>
ncmap("<F4>", "Bdelete")
ncmap("<F7>", "lua require'dap'.step_into()")
ncmap("<F6>", "lua require'dap'.step_over()")
ncmap("<F8>", "lua require'dap'.toggle_breakpoint()")
ncmap("<F12>", "lua require'dap'.continue()")
-- Auto completion
imap("<Tab>", "pumvisible() ? '<C-n>' : '<Tab>'", {expr = true})
imap("<S-Tab>", "pumvisible() ? '<C-p>' : '<S-Tab>'", {expr = true})
local cr_expr =
    "pumvisible() ? (empty(v:completed_item)?'<C-n>':'<C-g>u<CR>') : " ..
        "'<C-g>u<CR>'" -- <C-g>u starts a new item in the edit history
imap("<CR>", cr_expr, {expr = true})

---- Theme
function SolarizedTheme()
    -- Docstrings should be the same color as regular comments
    vim.cmd("hi! link rustCommentLineDoc Comment")
    vim.cmd("colorscheme solarized8")
    -- g.airline_theme = "solarized"
end

function GruvboxTheme()
    g.gruvbox_italic = 1
    g.gruvbox_bold = 1
    -- g.airline_theme = "gruvbox"
    vim.v["$BAT_THEME"] = "gruvbox"
    cmd("colorscheme gruvbox")
end

function MaterialTheme(style)
    g.material_style = style -- prefer "deep ocean"
    cmd("colorscheme material")
end

local function fallbackTheme()
    opt.background = "light"
    SolarizedTheme()
end

local function autoTheme()
    if env.TERM == "xterm-kitty" then
        if env.KITTY_THEME == "solarized-light" then
            opt.background = "light"
            SolarizedTheme()
        elseif env.KITTY_THEME == "solarized-dark" then
            opt.background = "dark"
            -- SolarizedTheme()
            MaterialTheme("deep ocean")
        else
            fallbackTheme()
        end
    else
        fallbackTheme()
    end
end

autoTheme()

vim.cmd("hi! link pythonSpaceError Normal")

-- Filetype overrides
api.nvim_exec([[
augroup lua_group
  au!
  au FileType lua nmap <F10> :Neomake<CR>
  au FileType lua nmap <Leader>cl :lclose<CR>
  au FileType lua nmap <Leader>cc :ll<CR>
  au FileType lua nmap <Leader>co :lopen<CR>
  au FileType lua nmap <Leader>f :call LuaFormat()<CR>
augroup END
]], false)

api.nvim_exec([[
augroup rust_group
  au!
  au FileType rust nmap <F10> :w<CR>:Neomake! cargo<CR>
  au FileType rust map t <Nop>
  au FileType rust nnoremap tn :TestNearest<CR>
  au FileType rust nnoremap tl :TestLast<CR>
  au FileType rust nnoremap tf :TestFile<CR>
augroup END
]], false)

---- Commands
