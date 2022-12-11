---- Aliases
local opt = vim.opt
local g = vim.g
local api = vim.api
local env = vim.env
local fn = vim.fn
local cmd = vim.cmd

local has_google, google = pcall(require, "google")

--- Packer
local packer_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(packer_path)) > 0 then
    PackerBootstrap = fn.system({
        'git', 'clone', '--depth', '1',
        'https://github.com/wbthomason/packer.nvim', packer_path
    })
end

require'packer'.startup(function(use)
    use 'wbthomason/packer.nvim'

    -- LSP & DAP & nvim
    use 'neovim/nvim-lspconfig'
    use {
        'williamboman/nvim-lsp-installer',
        config = function() require '_lsp_config' end
    }
    use 'nvim-lua/lsp-status.nvim'
    use {'mfussenegger/nvim-dap', config = function() require 'dap_config' end}
    use {
        'rcarriga/nvim-dap-ui',
        config = function() require'dapui'.setup {} end
    }
    use {
        'nvim-treesitter/nvim-treesitter',
        run = ':TSUpdate',
        config = function()
            require'nvim-treesitter.configs'.setup {
                ensure_installed = 'all',
                highlight = {enable = true},
                indent = {enable = true, disable = {"python", "yaml"}}
            }
            -- Custom parser for go template files
            local parser_config =
                require'nvim-treesitter.parsers'.get_parser_configs()
            parser_config.gotmpl = {
                install_info = {
                    url = "https://github.com/ngalaiko/tree-sitter-go-template",
                    files = {"src/parser.c"}
                },
                filetype = "gotmpl",
                used_by = {"gohtmltmpl", "gotexttmpl", "gotmpl"}
            }
        end
    }
    use 'nvim-treesitter/playground'
    use 'L3MON4D3/LuaSnip'
    use {
        'hrsh7th/nvim-cmp',
        requires = {
            'hrsh7th/cmp-nvim-lsp', 'hrsh7th/cmp-buffer', 'hrsh7th/cmp-path',
            'hrsh7th/cmp-nvim-lsp-signature-help', 'saadparwaiz1/cmp_luasnip',
            'neovim/nvim-lspconfig', 'L3MON4D3/LuaSnip', 'onsails/lspkind-nvim'
        },
        config = function()
            local cmp = require 'cmp'
            local luasnip = require 'luasnip'
            local sources = nil
            if has_google then
                sources = require"google".cmp_sources
            else
                sources = cmp.config.sources {
                    {name = 'nvim_lsp'}, {name = 'luasnip'}, {name = 'buffer'},
                    {name = 'nvim_lsp_signature_help'}
                }
            end

            cmp.setup {
                snippet = {
                    expand = function(args)
                        require'luasnip'.lsp_expand(args.body)
                    end
                },
                mapping = {
                    ['<C-d>'] = cmp.mapping(cmp.mapping.scroll_docs(-4),
                                            {'i', 'c'}),
                    ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4),
                                            {'i', 'c'}),
                    ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(),
                                                {'i', 'c'}),
                    ['<C-n>'] = cmp.mapping(cmp.mapping.select_next_item(),
                                            {'i', 'c'}),
                    ['<C-p>'] = cmp.mapping(cmp.mapping.select_prev_item(),
                                            {'i', 'c'}),
                    ['<CR>'] = cmp.mapping.confirm({select = true}),
                    ['<C-e>'] = cmp.mapping(cmp.mapping.close(), {'i'}),
                    ['<Tab>'] = cmp.mapping(function(fallback)
                        if luasnip.expand_or_jumpable() then
                            luasnip.expand_or_jump()
                        else
                            fallback()
                        end
                    end, {"i", "s"}),
                    ['<S-Tab>'] = cmp.mapping(function(fallback)
                        if luasnip.jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, {"i", "s"})
                },
                sources = sources,
                formatting = {format = require'lspkind'.cmp_format()}
            }
        end
    }
    use 'mhinz/vim-signify'
    use 'theHamsta/nvim-dap-virtual-text'
    use {
        'simrat39/rust-tools.nvim',
        requires = {'nvim-lua/plenary.nvim', 'mfussenegger/nvim-dap'},
        config = function()
            require'rust-tools'.setup {
                server = {
                    cargo = {loadOutDirsFromCheck = true},
                    on_attach = require'common'.on_attach
                }
            }
        end
    }
    use {
        'akinsho/flutter-tools.nvim',
        config = function()
            require'flutter-tools'.setup {
                decorations = {statusline = {device = true}},
                debugger = {enabled = true},
                widget_guides = {enabled = true},
                outline = {auto_open = false},
                lsp = {
                    on_attach = require'common'.on_attach,
                    settings = {lineLength = 100}
                }
            }

        end
    }
    use {
        'norcalli/nvim-terminal.lua',
        config = function() require'terminal'.setup() end
    }
    use {'weilbith/nvim-code-action-menu', cmd = 'CodeActionMenu'}
    use 'glepnir/lspsaga.nvim'
    use 'simrat39/symbols-outline.nvim'

    -- Theme
    use 'kyazdani42/nvim-web-devicons'
    use 'jeanlucthumm/vim-solarized8'
    use 'morhetz/gruvbox'
    use 'marko-cerovac/material.nvim'
    use {
        'rose-pine/neovim',
        config = function()
            require'rose-pine'.setup {
                dark_variant = 'moon',
                disable_italics = true
            }
        end
    }
    use 'folke/tokyonight.nvim'
    use 'tjdevries/colorbuddy.nvim'
    use 'projekt0n/github-nvim-theme'
    use 'savq/melange'

    -- UI
    use 'junegunn/fzf'
    use 'junegunn/fzf.vim'
    use {
        'ojroques/nvim-lspfuzzy',
        config = function() require'lspfuzzy'.setup {} end
    }
    use {
        'kyazdani42/nvim-tree.lua',
        config = function()
            require'nvim-tree'.setup {
                update_focused_file = {enable = true},
                update_cwd = true
            }
        end
    }
    use {'iamcco/markdown-preview.nvim', run = 'cd app && yarn install'}
    use {
        'nvim-telescope/telescope.nvim',
        requires = {'nvim-lua/plenary.nvim'},
        config = function()
            require'telescope'.setup {
                defaults = {
                    path_display = {"smart"},
                    mappings = {
                        i = {
                            ['<C-k>'] = 'move_selection_previous',
                            ['<C-j>'] = 'move_selection_next'
                        },
                        n = {['<C-c>'] = 'close'}
                    }
                }
            }
            require'telescope'.load_extension('vim_bookmarks')
            require'telescope'.load_extension('flutter')
        end
    }
    use 'tom-anders/telescope-vim-bookmarks.nvim'
    use 'nvim-lualine/lualine.nvim' -- configured in the theme section
    use 'mhinz/vim-startify'
    use {
        'rcarriga/nvim-notify',
        config = function() vim.notify = require "notify" end
    }

    -- Editor
    use 'tpope/vim-commentary'
    use 'tpope/vim-fugitive'
    use 'tpope/vim-dispatch'
    use 'moll/vim-bbye'
    use {
        'jeanlucthumm/nvim-lua-format',
        config = function()
            require'nvim-lua-format'.setup {
                save_if_unsaved = true,
                default = {
                    chop_down_table = true,
                    indent_width = 4,
                    continuation_indent_width = 4
                }
            }
        end
    }
    use 'pseewald/vim-anyfold'
    use {
        'onsails/lspkind-nvim',
        config = function() require'lspkind'.init {} end
    }
    use {
        'windwp/nvim-autopairs',
        config = function()
            require'nvim-autopairs'.setup {}
            require'cmp'.event:on('confirm_done',
                                  require'nvim-autopairs.completion.cmp'.on_confirm_done(
                                      {map_char = {tex = ''}}))
        end
    }
    use 'bmundt6/workflowish'
    use {'psliwka/vim-smoothie', cond = function() return not vim.g.neovide end}
    use 'rhysd/conflict-marker.vim'
    use 'rhysd/vim-clang-format'
    use {
        'RishabhRD/nvim-lsputils',
        requires = {'RishabhRD/popfix'},
        config = function()
            vim.lsp.handlers['textDocument/codeAction'] =
                require'lsputil.codeAction'.code_action_handler
        end
    }

    -- Functional
    use 'MattesGroeger/vim-bookmarks'
    use 'neomake/neomake'
    use 'vim-test/vim-test'
    use '907th/vim-auto-save'
    use {
        'ThePrimeagen/harpoon',
        config = function()
            require'harpoon'.setup {global_settings = {enter_on_sendcmd = true}}
            require'telescope'.load_extension('harpoon')
        end
    }
    use {
        'CRAG666/code_runner.nvim',
        requires = 'nvim-lua/plenary.nvim',
        config = function()
            require'code_runner'.setup {filetype = {python = "python -u"}}
        end
    }

    if has_google then google.packer(use) end
    if PackerBootstrap then require('packer').sync() end
end) -- packer

-- For plugin development. Link plugin dir to dev
cmd [[ set rtp+=$HOME/.config/nvim/dev ]]

---- Global options
g.neomake_open_list = 2
g.auto_save = 0
g.auto_save_events = {'InsertLeave', 'TextChanged', 'CursorHold'}
g.neovide_cursor_animation_length = 0.05
g.bookmark_no_default_key_mappings = 1
g.symbols_outline = {show_symbol_details = false}
g.mapleader = ' ' -- sets <Leader> to <space>
g.startify_change_to_dir = 0 -- do not change cwd when opening files
g.startify_session_autoload = 1 -- automatically source session if Session.vim is found
g.gitgutter_map_keys = 0 -- disable default keybindings for gitgutter
g.foldlevel = 99 -- no folds on file open
vim.v['test#strategy'] = 'neomake'
vim.wo.foldmethod = 'expr' -- expression based folding to enable treesitter
vim.wo.foldexpr = 'nvim_treesitter#foldexpr()' -- treesitter folding
vim.wo.foldlevel = 99 -- no folds on file open

---- Neovim options
opt.tabstop = 2
opt.shiftwidth = 2
opt.termguicolors = true
opt.expandtab = true
opt.number = true
opt.splitright = true
opt.hidden = true
opt.mouse = 'a'
opt.updatetime = 500
opt.guifont = 'JetBrainsMono Nerd Font:h8'
opt.completeopt = 'menu,menuone,noselect'
opt.showmode = false
if fn.has('nvim-0.5.0') == 1 then opt.signcolumn = 'number' end

---- Theme
local lualine_theme = 'solarized_light'
function SolarizedTheme(background)
    -- Docstrings should be the same color as regular comments
    vim.cmd('hi! link rustCommentLineDoc Comment')
    vim.cmd('colorscheme solarized8')
    opt.background = background
end
function SolarizedLuaTheme(background)
    opt.background = background
    if background == 'dark' then
        lualine_theme = 'solarized_dark'
    else
        lualine_theme = 'solarized_light'
    end
    g.solarized_italics = 0
    cmd('colorscheme solarized')
end
function GruvboxTheme(background)
    g.gruvbox_italic = 1
    g.gruvbox_bold = 1
    opt.background = background
    vim.v['$BAT_THEME'] = 'gruvbox'
    cmd('colorscheme gruvbox')
end
function MaterialTheme(style) -- prefer 'deep ocean'
    g.material_style = style
    lualine_theme = 'material-nvim'
    cmd('colorscheme material')
end
function RosePineTheme(style) -- prefer 'dawn' light, 'moon' dark
    if style == 'dawn' then
        opt.background = 'light'
    else
        opt.background = 'dark'
    end
    lualine_theme = 'rose-pine'
    cmd('colorscheme rose-pine')
    require'rose-pine'.setup {dark_variant = 'moon', disable_italics = true}
end
function TokyoNight(background)
    opt.background = background
    lualine_theme = 'tokyonight'
    cmd('colorscheme tokyonight')
end
function GithubTheme(background)
    opt.background = background
    if background == 'dark' then
        lualine_theme = 'github_dark'
    else
        lualine_theme = 'github_light'
    end
    require'github-theme'.setup {theme_style = background}
end
function MelangeTheme(background)
    opt.background = background
    lualine_theme = 'auto'
    cmd('colorscheme melange')
end

local function fallbackTheme()
    -- SolarizedLuaTheme('light')
    -- MaterialTheme('lighter')
    -- MaterialTheme('oceanic')
    -- RosePineTheme('dawn')
    MelangeTheme('dark')
end
local function autoTheme()
    if env.TERM == 'xterm-kitty' then
        if env.KITTY_THEME == 'solarized-light' then
            -- MaterialTheme('lighter')
            RosePineTheme('dawn')
            -- SolarizedLuaTheme('light')
            -- GithubTheme('light')
        elseif env.KITTY_THEME == 'solarized-dark' then
            MaterialTheme('deep ocean')
            -- GithubTheme('dark')
        else
            fallbackTheme()
        end
    elseif env.THEME == 'solarized-light' then
        -- SolarizedLuaTheme('light')
        SolarizedLuaTheme('light')
        -- RosePineTheme('dawn')
    else
        fallbackTheme()
    end
end
autoTheme()
vim.cmd('hi! link pythonSpaceError Normal')

local function lsp_status_component() return require'lsp-status'.status() end
require'lualine'.setup {
    options = {theme = lualine_theme, extensions = {'quickfix', 'nvim-tree'}},
    sections = {
        lualine_x = {lsp_status_component, 'encoding', 'fileformat', 'filetype'}
    }
}

---- Keymap (note that some keys are defined in _lsp_config.lua)
local map = require'common'.map
local nmap = require'common'.nmap
local imap = require'common'.imap
local vcmap = require'common'.vcmap
local ncmap = require'common'.ncmap

-- visual
map('v', '<Leader>y', '\"+y') -- copy to system clipboard
nmap('<Leader>p', '\"+p') -- paste from system clipboard
-- g
nmap('gt', ':tabe<CR>:term<CR>:file term:cli<CR>i')
ncmap('gr', 'Telescope lsp_references')
ncmap('gio', 'Telescope oldfiles')
-- c
nmap('cp', ':let @" = expand("%:p")<CR>') -- yank file path
-- <Leader>
ncmap('<Leader>q', 'qall')
ncmap('<Leader>o', 'Telescope lsp_document_symbols')
ncmap('<Leader>O', 'Telescope lsp_dynamic_workspace_symbols')
ncmap('<Leader>d', 'Telescope lsp_document_diagnostics')
ncmap('<Leader>D', 'Telescope lsp_workspace_diagnostics')
ncmap('<Leader>s', 'SymbolsOutline')
ncmap('<Leader>t', 'NvimTreeFocus')
ncmap('<Leader>a', 'Lspsaga code_action')
vcmap('<Leader>a', '<C-U>Lspsaga range_code_action')
ncmap('<Leader><Leader>', 'write')
-- <Leader>v    nvim config
ncmap('<Leader>ve', ":exe 'tabedit' stdpath('config').'/init.lua'")
nmap('<Leader>vs', ":exe 'source' stdpath('config').'/init.lua'<CR>")
-- <Leader>c    quickfix, cd
ncmap('<Leader>cl', 'cclose')
ncmap('<Leader>cc', 'cc')
ncmap('<Leader>co', 'copen')
ncmap('<Leader>cd', 'cd %:h')
-- <Leader>b    bookmarks
ncmap('<Leader>bb', 'BookmarkToggle')
ncmap('<Leader>ba', 'BookmarkAnnotate')
ncmap('<Leader>bo', 'Telescope vim_bookmarks all')
-- <Leader>h    hunks + harpoon + help
ncmap('<Leader>hu', 'SignifyHunkUndo')
ncmap('<Leader>hd', 'SignifyHunkDiff')
ncmap('<Leader>ha', 'lua require"harpoon.mark".add_file()')
ncmap('<Leader>ho', 'lua require"harpoon.ui".toggle_quick_menu()')
ncmap('<Leader>hh', 'Telescope help_tags')
-- <Leader>d    debugging
ncmap('<Leader>dd', 'lua require"dap".toggle_breakpoint()')
ncmap('<Leader>dco', 'lua require"dapui".open()')
ncmap('<Leader>dcl', 'lua require"dapui".close()')
ncmap('<Leader>dt', 'lua require"dap".terminate()')
ncmap('<Leader>ds', 'lua require"dap".continue()')
-- <Leader>l    harpoon
ncmap('<Leader>lh', 'lua require"harpoon.ui".nav_file(1)')
ncmap('<Leader>lj', 'lua require"harpoon.ui".nav_file(2)')
ncmap('<Leader>lk', 'lua require"harpoon.ui".nav_file(3)')
-- <Leader>w    running
ncmap('<Leader>ww', 'RunCode')
ncmap('<Leader>wc', 'RunClose')

-- <C-*> and <A-*>
ncmap('<C-h>', 'tabp')
ncmap('<C-l>', 'tabn')
nmap('<C-j>', '<C-e>') -- scroll one line up
nmap('<C-k>', '<C-y>') -- scroll one line down
imap('<C-v>', '<C-r>+')
map('t', '<C-h>', '<C-\\><C-n><Cmd>:tabp<CR>')
map('t', '<C-l>', '<C-\\><C-n><Cmd>:tabn<CR>')
map('t', '<C-w><C-w>', '<C-\\><C-l><C-w>:tabn<C-w>')
map('t', '<C-\\><C-\\>', '<C-\\><C-n>')
ncmap('<C-p>', 'Telescope commands')
ncmap('<C-e>',
      'lua require"telescope.builtin".buffers({ sort_lastused = true, ignore_current_buffer = true })')
nmap('<C-q>', '<C-^>')
ncmap('<M-e>', 'Telescope find_files')
ncmap('<C-e>', 'Telescope buffers')
ncmap('<C-s>', 'Telescope harpoon marks')
ncmap('<M-1>', 'NvimTreeToggle')
ncmap('<M-f>', 'NvimTreeFindFile')
ncmap('<C-w>d', 'lua OpenInRight()')
-- <F*>
ncmap('<F4>', 'Bdelete')
ncmap('<F7>', 'lua require"dap".step_into()')
ncmap('<F6>', 'lua require"dap".step_over()')

-- TODO:  There's a lua API for this now
---- Filetype overrides
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

api.nvim_exec([[
augroup proto_group
  au!
  au FileType proto nmap <Leader>f <Cmd>ClangFormat<CR>
augroup END
]], false)

api.nvim_exec([[
augroup python_group
  au!
  au FileType python nnoremap <Leader>f :w<CR> :!black %<CR>
augroup END
]], false)

---- Util
function HighlightGroups()
    -- Gives you all highlight groups under the cursor
    local stack = fn.synstack(fn.line('.'), fn.col('.'))
    if next(stack) == nil then
        print('Syntax stack is empty')
        return
    end
    for _, val in ipairs(stack) do print(fn.synIDattr(val, 'name')) end
end
cmd('command! -nargs=0 HighlightGroups lua HighlightGroups()')


function OpenInRight()
  local wins = api.nvim_tabpage_list_wins(0)
  local left_buf = api.nvim_win_get_buf(wins[1])
  local left_pos = api.nvim_win_get_cursor(wins[1])
  api.nvim_win_set_buf(wins[2], left_buf)
  api.nvim_win_set_cursor(wins[2], left_pos)
end

if has_google then google.setup() end
