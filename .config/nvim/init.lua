---- Aliases
local opt = vim.opt
local g = vim.g
local api = vim.api
local env = vim.env
local fn = vim.fn
local cmd = vim.cmd

---- Plugins
-- LuaFormatter off
require "paq" {
    "savq/paq-nvim",
    "nvim-lua/plenary.nvim",

    -- LSP & DAP & nvim
    "neovim/nvim-lspconfig",
    "kabouzeid/nvim-lspinstall",
    "nvim-lua/lsp-status.nvim",
    "mfussenegger/nvim-dap",
    "rcarriga/nvim-dap-ui",
    "hrsh7th/nvim-compe",
    {"nvim-treesitter/nvim-treesitter", run = function() cmd("TSUpdate") end},
    "glepnir/lspsaga.nvim",
    "theHamsta/nvim-dap-virtual-text",
    "simrat39/rust-tools.nvim",
    "akinsho/flutter-tools.nvim",

    -- Theme
    "kyazdani42/nvim-web-devicons",
    "jeanlucthumm/vim-solarized8",
    "morhetz/gruvbox",
    "marko-cerovac/material.nvim",
    "rose-pine/neovim",
    "ishan9299/nvim-solarized-lua",

    -- UI
    "junegunn/fzf",
    "junegunn/fzf.vim",
    "ojroques/nvim-lspfuzzy",
    "kyazdani42/nvim-tree.lua",
    {"iamcco/markdown-preview.nvim", run = "cd app && yarn install"},
    "airblade/vim-gitgutter",
    "nvim-telescope/telescope.nvim",
    "simrat39/symbols-outline.nvim",
    "tom-anders/telescope-vim-bookmarks.nvim",
    "simrat39/symbols-outline.nvim",
    "shadmansaleh/lualine.nvim",
    "mhinz/vim-startify",

    -- Editor
    "tpope/vim-commentary",
    "tpope/vim-fugitive",
    "tpope/vim-dispatch",
    "moll/vim-bbye",
    "jeanlucthumm/nvim-lua-format",
    "pseewald/vim-anyfold",
    "onsails/lspkind-nvim",
    "windwp/nvim-autopairs",
    "bmundt6/workflowish",
    "psliwka/vim-smoothie",

    -- Functional
    "MattesGroeger/vim-bookmarks",
    "neomake/neomake",
    "vim-test/vim-test",
    "907th/vim-auto-save"
}
-- LuaFormatter on

-- For plugin development. Link plugin dir to dev
cmd [[ set rtp+=$HOME/.config/nvim/dev ]]

---- Global options
g.neomake_open_list = 2
g.auto_save = 0
g.auto_save_events = {"InsertLeave", "TextChanged", "CursorHold"}
g.neovide_cursor_animation_length = 0.05
g.bookmark_no_default_key_mappings = 1
g.symbols_outline = {show_symbol_details = false}
g.mapleader = " " -- sets <Leader> to <space>
g.dap_virtual_text = true
g.startify_change_to_dir = 0 -- do not change cwd when opening files
g.startify_session_autoload = 1 -- automatically source session if Session.vim is found
g.gitgutter_map_keys = 0 -- disable default keybindings for gitgutter
vim.v["test#strategy"] = "neomake"

-- Util
function PrintTable(table)
    for key, value in pairs(table) do print(key, value) end
end

---- Plugin configuration
-- LSP keybindings

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
        local config = {
            capabilities = capabilities,
            on_attach = require'common'.on_attach
        }

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
        name = "default",
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
dap.configurations.rust = {
    {
        name = "default",
        type = "lldb",
        request = "launch",
        program = '${workspaceFolder}/target/debug/${workspaceFolderBasename}',
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
        args = {},
        runInTerminal = false
    },
    {
        name = "rustc stage1 debug",
        type = "lldb",
        request = "launch",
        program = "/home/jeanluc/Code/rust/build/x86_64-unknown-linux-gnu/stage1/bin/rustc",
        cwd = '${workspaceFolder}',
        stopOnEntry = false,

        args = function()
            local path = fn.input("Target rust project: ",
                                  "/home/jeanluc/Code/", "file")
            local target = path:match(".+/(.+)/$") -- extract dir name
            return {
                "--crate-name",
                target,
                "--edition=2018",
                path .. "/src/main.rs",
                "--error-format=json",
                "--json=diagnostic-rendered-ansi",
                "--crate-type",
                "bin",
                "--emit=dep-info,link",
                "-C",
                "embed-bitcode=no",
                "-C",
                "debuginfo=2",
                -- These hashcodes are for mangling, and I copied this one from a cargo project
                "-C",
                "metadata=3a8a540162ab7ee9",
                "-C",
                "extra-filename=-3a8a540162ab7ee9",
                "--out-dir",
                path .. "target/debug/deps",
                "-C",
                "incremental=" .. path .. "target/debug/incremental",
                "-L",
                "dependency=" .. path .. "target/debug/deps"
            }
        end,
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
    highlight = {enable = true},
    indent = {enable = true}
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
require"telescope".load_extension("flutter")
-- Lualine is configured in the theme section
require"rust-tools".setup {}
require"nvim-autopairs".setup {}
require"nvim-autopairs.completion.compe".setup {
    map_cr = true, -- overide <CR> mapping in insert mode
    map_complete = true, -- auto insert '(' after select function or method
    auto_select = true -- pick the first item in suggestion automatically?
}
require"flutter-tools".setup {
    decorations = {statusline = {device = true}},
    debugger = {enabled = true},
    widget_guides = {enabled = true},
    outline = {auto_open = true},
    lsp = {on_attach = require'common'.on_attach, settings = {lineLength = 100}}
}
require"nvim-lua-format".setup {
    save_if_unsaved = true,
    default = {chop_down_table = true}
}

require"nvim-lua-format".setup {save_if_unsaved = true}

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
opt.guifont = "JetBrains_Mono_Medium_Nerd_Font_Complete:h11"
opt.completeopt = "menuone,noselect"
if vim.fn.has("nvim-0.5.0") == 1 then opt.signcolumn = "number" end

---- Theme
local lualine_theme = "solarized_light"
function SolarizedTheme(background)
    -- Docstrings should be the same color as regular comments
    vim.cmd("hi! link rustCommentLineDoc Comment")
    vim.cmd("colorscheme solarized8")
    opt.background = background
end
function SolarizedLuaTheme(background)
    opt.background = background
    if background == "dark" then
        lualine_theme = "solarized_dark"
    else
        lualine_theme = "solarized_light"
    end
    g.solarized_italics = 0
    cmd("colorscheme solarized")
end
function GruvboxTheme(background)
    g.gruvbox_italic = 1
    g.gruvbox_bold = 1
    opt.background = background
    vim.v["$BAT_THEME"] = "gruvbox"
    cmd("colorscheme gruvbox")
end
function MaterialTheme(style) -- prefer "deep ocean"
    g.material_style = style
    lualine_theme = "material-nvim"
    cmd("colorscheme material")
end
function RosePineTheme(style) -- prefer "dawn" light, "moon" dark
    g.rose_pine_variant = style
    g.rose_pine_disable_italics = true
    lualine_theme = "rose-pine"
    cmd("colorscheme rose-pine")
end
local function fallbackTheme()
    lualine_theme = "solarized_light"
    SolarizedTheme("light")
end
local function autoTheme()
    if env.TERM == "xterm-kitty" then
        if env.KITTY_THEME == "solarized-light" then
            -- MaterialTheme("lighter")
            RosePineTheme("dawn")
            -- SolarizedLuaTheme("light")
        elseif env.KITTY_THEME == "solarized-dark" then
            MaterialTheme("deep ocean")
        else
            fallbackTheme()
        end
    elseif env.THEME == "solarized-light" then
        -- SolarizedLuaTheme("light")
        SolarizedTheme("light")
        -- RosePineTheme("dawn")
    else
        fallbackTheme()
    end
end
autoTheme()
vim.cmd("hi! link pythonSpaceError Normal")

local function lsp_status_component() return require'lsp-status'.status() end
require"lualine".setup {
    options = {theme = lualine_theme, extensions = {"quickfix", "nvim-tree"}},
    sections = {
        lualine_x = {lsp_status_component, 'encoding', 'fileformat', 'filetype'}
    }
}

---- Keymap (note that some keys are defined in the LSP section)
local function map(mode, lhs, rhs, opts)
    local options = {noremap = true}
    if opts then options = vim.tbl_extend("force", options, opts) end
    api.nvim_set_keymap(mode, lhs, rhs, options)
end
local function nmap(...) map("n", ...) end
local function ncmap(lhs, rhs, ...) nmap(lhs, "<Cmd>" .. rhs .. "<CR>", ...) end
local function imap(...) map("i", ...) end

-- visual
map("v", "<Leader>y", "\"*y") -- copy to system clipboard
-- g
nmap("gt", ":tabe<CR>:term<CR>i")
ncmap("gr", "Telescope lsp_references")
-- <Leader>
ncmap("<Leader>q", "qall")
ncmap("<Leader>o", "Telescope lsp_document_symbols")
ncmap("<Leader>O", "Telescope lsp_dynamic_workspace_symbols")
ncmap("<Leader>d", "Telescope lsp_document_diagnostics")
ncmap("<Leader>D", "Telescope lsp_workspace_diagnostics")
ncmap("<Leader>a", "Telescope lsp_code_actions")
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
-- <Leader>h    hunks
ncmap("<Leader>hp", "GitGutterPrevHunk")
ncmap("<Leader>hn", "GitGutterNextHunk")
ncmap("<Leader>hs", "GitGutterStageHunk")
ncmap("<Leader>hu", "GitGutterUndoHunk")
ncmap("<Leader>hq", "GitGutterQuickFix")
ncmap("<Leader>hQ", "GitGutterQuickFixCurrentFile")
-- <C-*> and <A-*>
ncmap("<C-h>", "tabp")
ncmap("<C-l>", "tabn")
map("t", "<C-h>", "<C-\\><C-n><Cmd>:tabp<CR>")
map("t", "<C-l>", "<C-\\><C-l><Cmd><CR>")
map("t", "<C-w><C-w>", "<C-\\><C-l><C-w>:tabn<C-w>")
ncmap("<C-p>", "Telescope commands")
ncmap("<C-e>", "Telescope buffers")
ncmap("<C-q>", "Telescope quickfix")
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

-- Filetype overrides
api.nvim_exec([[
augroup lua_group
  au!
  au FileType lua nmap <F10> :Neomake<CR>
  au FileType lua nmap <Leader>cl :lclose<CR>
  au FileType lua nmap <Leader>cc :ll<CR>
  au FileType lua nmap <Leader>co :lopen<CR>
  au FileType lua nmap <Leader>f :lua require'nvim-lua-format'.format()<CR>
  au FileType lua set tabstop=4
  au FileType lua set shiftwidth=4
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
  au FileType rust let g:auto_save=1
augroup END
]], false)

---- Commands
function HighlightGroups()
    -- Gives you all highlight groups under the cursor
    local stack = fn.synstack(fn.line("."), fn.col("."))
    if next(stack) == nil then
        print("Syntax stack is empty")
        return
    end
    for _, val in ipairs(stack) do print(fn.synIDattr(val, "name")) end
end
cmd("command! -nargs=0 HighlightGroups lua HighlightGroups()")

pcall(require, 'google')
