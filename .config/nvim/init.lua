--- Aliases
local opt = vim.opt
local g = vim.g
local api = vim.api
local env = vim.env
local fn = vim.fn
local cmd = vim.cmd

g.mapleader = ' ' -- sets <Leader> to <space>

local function file_exists(path)
  local stat = vim.loop.fs_stat(path)
  return stat or false
end

local function find_existing_path(paths)
  for _, path in ipairs(paths) do
    if file_exists(path) then
      return path
    end
  end
  return nil
end

HasGoogle = file_exists(fn.stdpath('config') .. '/lua/google.lua')

--- Lazy bootstrap
local lazypath = fn.stdpath('data') .. '/lazy/lazy.nvim'
if not file_exists(lazypath) then
  vim.notify('Bootstraping lazy.nvim...')
  fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  })
end
opt.rtp:prepend(lazypath)

local plugin_spec = {
  { 'nvim-lua/plenary.nvim' },

  --- LSP & DAP & nvim
  {
    'folke/neodev.nvim',
    opts = {
      pathStrict = true,
    },
  }, -- lua LSP setup for better nvim integration
  {
    'neovim/nvim-lspconfig',
    dependencies = { 'folke/neodev.nvim' },
    config = function()
      local function extend(config)
        return vim.tbl_deep_extend('force', {
          capabilities = require'common'.capabilities(),
          on_attach = require'common'.on_attach,
          flags = { debounce_text_changes = 150 },
        }, config)
      end
      local lspconfig = require'lspconfig'
      lspconfig.lua_ls.setup(extend {
        settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
            format = {
              -- https://github.com/CppCXY/EmmyLuaCodeStyle/blob/master/lua.template.editorconfig
              enable = true,
              defaultConfig = {
                indent_size = '2',
                quote_style = 'single',
                max_line_length = '100',
                trailing_table_separator = 'smart',
                space_before_function_call_single_arg = 'only_table',
              },
            },
          },
        },
      })
      lspconfig.pyright.setup(extend {})
      lspconfig.gopls.setup(extend {})
    end,
  },
  {
    'nvimtools/none-ls.nvim',
    enabled = not HasGoogle,
    config = function()
      local n = require('null-ls')
      n.setup {
        sources = {
          n.builtins.formatting.black,
          n.builtins.formatting.fish_indent,
          n.builtins.formatting.mdformat,
          n.builtins.formatting.clang_format,
          n.builtins.formatting.buf,
          n.builtins.formatting.prettier,
          n.builtins.formatting.dart_format,
          n.builtins.formatting.isort,
          n.builtins.diagnostics.fish,
          n.builtins.diagnostics.actionlint,
          n.builtins.diagnostics.mypy,
        },
      }
    end,
  },
  { 'nvim-lua/lsp-status.nvim' },
  { 'mfussenegger/nvim-dap',   config = function() require'dap_config' end },
  {
    'rcarriga/nvim-dap-ui',
    opts = {},
    dependencies = { 'nvim-neotest/nvim-nio' },
  },
  {
    'mfussenegger/nvim-dap-python',
    config = function()
      require'dap-python'.setup('~/.virtualenv/debug/bin/python')
      require'dap-python'.test_runner = 'pytest'
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
      require'nvim-treesitter.configs'.setup {
        ensure_installed = {
          'c',
          'lua',
          'rust',
          'fish',
          'markdown',
          'markdown_inline',
        },
        highlight = { enable = true },
        indent = {
          enable = true,
          disable = { 'dart' },
        },
      }
      vim.wo.foldmethod = 'expr'                     -- expression based folding to enable treesitter
      vim.wo.foldexpr = 'nvim_treesitter#foldexpr()' -- treesitter folding
      -- Custom parser for go template files
      local parser_config =
          require'nvim-treesitter.parsers'.get_parser_configs()
      parser_config.gotmpl = {
        install_info = {
          url = 'https://github.com/ngalaiko/tree-sitter-go-template',
          files = { 'src/parser.c' },
        },
        filetype = 'gotmpl',
        used_by = { 'gohtmltmpl', 'gotexttmpl', 'gotmpl' },
      }
      -- See https://github.com/nvim-treesitter/nvim-treesitter/issues/4945
      parser_config.dart = {
        install_info = {
          url = 'https://github.com/UserNobody14/tree-sitter-dart',
          files = { 'src/parser.c', 'src/scanner.c' },
          revision = '8aa8ab977647da2d4dcfb8c4726341bee26fbce4', -- The last commit before the snail speed
        },
      }
    end,
  },
  { 'nvim-treesitter/playground' },
  {
    'L3MON4D3/LuaSnip',
    config = function()
      require'luasnip'.config.set_config({
        region_check_events = 'InsertEnter',
        delete_check_events = 'InsertLeave',
      })
      require'luasnip.loaders.from_lua'.lazy_load({ paths = { './snippets' } })
    end,
  },
  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-buffer',
      'hrsh7th/cmp-path',
      'hrsh7th/cmp-nvim-lsp-signature-help',
      'saadparwaiz1/cmp_luasnip',
      'neovim/nvim-lspconfig',
      'L3MON4D3/LuaSnip',
      'onsails/lspkind-nvim',
    },
    config = function()
      local cmp = require'cmp'
      local luasnip = require'luasnip'
      local conf = {
        snippet = {
          expand = function(args)
            require'luasnip'.lsp_expand(args.body)
          end,
        },
        mapping = {
          ['<C-d>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
          ['<C-f>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
          ['<C-Space>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
          ['<C-n>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'i', 'c' }),
          ['<C-p>'] = cmp.mapping(cmp.mapping.select_prev_item(), { 'i', 'c' }),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<C-e>'] = cmp.mapping(cmp.mapping.close(), { 'i' }),
          ['<Tab>'] = cmp.mapping(function(fallback)
            if luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            elseif not HasGoogle and require'copilot.suggestion'.is_visible() then
              require'copilot.suggestion'.accept()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<C-Tab>'] = cmp.mapping(function(fallback)
            local copilot = require'copilot.suggestion'
            if not HasGoogle and copilot.is_visible() then
              copilot.accept_line()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
        },
        sources = {
          { name = 'luasnip',                 priority = 50 },
          { name = 'nvim_lsp',                priority = 10, max_item_count = 20 },
          { name = 'nvim_lsp_signature_help', priority = 10 },
          { name = 'buffer',                  priority = 1 },
        },
        formatting = { format = require'lspkind'.cmp_format() },
        sorting = { priority_weight = 10 },
      }
      if HasGoogle then conf = require'google'.update_cmp_config(conf) end
      cmp.setup(conf)
    end,
  },
  { 'mhinz/vim-signify' }, -- TODO look into nvim version
  {
    'theHamsta/nvim-dap-virtual-text',
    opts = {},
  },
  {
    'simrat39/rust-tools.nvim',
    config = function()
      -- Gives pretty pretting during Rust debugging by hijacking the CodeLLDB
      -- extension from VSCode.
      local paths = {
        vim.env.HOME .. '/.vscode-oss/extensions/vadimcn.vscode-lldb-1.9.2-universal',
        vim.env.HOME .. '/.vscode/extensions/vadimcn.vscode-lldb-1.9.2',
      }
      local extension_path = find_existing_path(paths)
      local this_os = vim.loop.os_uname().sysname;

      local dap = {}
      if extension_path then
        dap.adapter = require'rust-tools.dap'.get_codelldb_adapter(
          extension_path .. '/adapter/codelldb',
          extension_path .. '/lldb/lib/liblldb' .. (this_os == 'Linux' and '.so' or '.dylib')
        )
      end
      require'rust-tools'.setup {
        server = {
          cargo = { loadOutDirsFromCheck = true },
          on_attach = require'common'.on_attach,
          capabilities = require'common'.capabilities(),
        },
        dap = dap,
        tools = {
          inlay_hints = {
            highlight = 'InlayHints',
          },
        },
      }
    end,
  },
  {
    'ray-x/go.nvim',
    opts = {
      lsp_codelens = false,
    },
    event = 'CmdlineEnter',
    ft = { 'go', 'gomod' },
    dependencies = {
      'ray-x/guihua.lua',
    },
  },
  {
    'akinsho/flutter-tools.nvim',
    config = function()
      require'flutter-tools'.setup {
        decorations = { statusline = { device = true } },
        debugger = { enabled = true },
        widget_guides = { enabled = true },
        outline = { auto_open = false },
        lsp = {
          on_attach = require'common'.on_attach,
          settings = { lineLength = 100 },
        },
      }
    end,
  },
  {
    'pmizio/typescript-tools.nvim',
    dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig', 'nvim-lua/lsp-status.nvim' },
    enabled = not HasGoogle,
    config = function()
      require'typescript-tools'.setup {
        on_attach = require'common'.on_attach,
        capabilities = require'common'.capabilities(),
      }
    end,
  },
  { 'aznhe21/actions-preview.nvim' },
  {
    'simrat39/symbols-outline.nvim',
    config = function()
      require'symbols-outline'.setup({
        autofold_depth = 1,
        relative_width = false,
        width = 40,
      })
    end,
  },
  {
    'zbirenbaum/copilot.lua',
    enabled = not HasGoogle,
    cmd = 'Copilot',
    event = 'InsertEnter',
    opts = {
      panel = {
        auto_refresh = true,
      },
      suggestion = {
        auto_trigger = true,
      },
    },
  },

  --- Theme
  { 'nvim-tree/nvim-web-devicons' },
  {
    'ellisonleao/gruvbox.nvim',
    config = function() require'gruvbox'.setup { bold = false } end,
  },
  { 'marko-cerovac/material.nvim' },
  {
    'rose-pine/neovim',
    config = function()
      require'rose-pine'.setup { dark_variant = 'moon', disable_italics = true }
    end,
  },
  { 'folke/tokyonight.nvim' },
  { 'tjdevries/colorbuddy.nvim' },
  { 'projekt0n/github-nvim-theme' },
  { 'savq/melange' },
  {
    'mcchrish/zenbones.nvim',
    dependencies = { 'rktjmp/lush.nvim' },
  },
  { 'maxmx03/solarized.nvim' },

  --- UI
  { 'iamcco/markdown-preview.nvim', build = 'cd app && yarn install' },
  {
    'nvim-telescope/telescope.nvim',
    config = function()
      local actions = require'telescope.actions'
      require'telescope'.setup {
        defaults = {
          path_display = { 'smart' },
          mappings = {
            i = {
              ['<C-k>'] = 'move_selection_previous',
              ['<C-j>'] = 'move_selection_next',
              ['<C-x>'] = actions.delete_buffer,
              ['<C-u>'] = actions.preview_scrolling_up,
              ['<C-d>'] = actions.preview_scrolling_down,
            },
            n = { ['<C-c>'] = 'close' },
          },
          preview = { timeout = 2000 },
        },
      }
      require'telescope'.load_extension('flutter')
    end,
  },
  -- TODO look at config for this for lazy.nvim
  { 'nvim-lualine/lualine.nvim' }, -- configured in the theme section
  {
    -- startup screen
    'mhinz/vim-startify',
    config = function()
      g.startify_change_to_dir = 0    -- do not change cwd when opening files
      g.startify_session_autoload = 1 -- automatically source session if Session.vim is found
    end,
  },
  { 'rcarriga/nvim-notify' },      -- pretty notifications
  { 'xiyaowong/virtcolumn.nvim' }, -- makes virtual column a pixel wide
  {
    'stevearc/dressing.nvim',
    opts = {},
  },


  --- Editor
  { 'tpope/vim-commentary' },
  { 'moll/vim-bbye' }, -- better version of :bdelete
  -- TODO figure out keybindings
  { 'pseewald/vim-anyfold' },
  { 'onsails/lspkind-nvim', config = function() require'lspkind'.init {} end },
  {
    'windwp/nvim-autopairs',
    config = function()
      require'nvim-autopairs'.setup {}
      require'cmp'.event:on('confirm_done',
        require'nvim-autopairs.completion.cmp'.on_confirm_done(
          { map_char = { tex = '' } }))
    end,
  },
  { 'psliwka/vim-smoothie', cond = function() return not vim.g.neovide end },
  {
    'akinsho/git-conflict.nvim',
    version = '*',
    config = true,
  },
  { 'ThePrimeagen/harpoon' },
  {
    'ggandor/leap.nvim',
    config = function()
      require'leap'.add_default_mappings()
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require'nvim-treesitter.configs'.setup {
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ['af'] = '@function.outer',
              ['if'] = '@function.inner',
              ['ab'] = '@block.outer',
              ['ib'] = '@block.inner',
              ['ip'] = '@parameter.inner',
              ['ap'] = '@parameter.outer',
              ['ic'] = '@call.inner',
              ['ac'] = '@call.outer',
            },
          },
          move = {
            enable = true,
            set_jumps = true,
            goto_next_start = {
              [']f'] = { query = { '@function.outer', '@class.outer' } },
              [']b'] = '@block.outer',
            },
            goto_previous_start = {
              ['[f'] = { query = { '@function.outer', '@class.outer' } },
              ['[b'] = '@block.outer',
            },
            goto_next_end = {
              [']F'] = '@function.outer',
              [']B'] = '@block.outer',
            },
            goto_previous_end = {
              ['[F'] = '@function.outer',
              ['[B'] = '@block.outer',
            },
          },
        },
      }
    end,
  },

  -- Functional
  {
    '907th/vim-auto-save',
    config = function()
      g.auto_save = 0
      g.auto_save_events = { 'InsertLeave', 'TextChanged', 'CursorHold' }
    end,
  },
  {
    'CRAG666/code_runner.nvim',
    config = function()
      require'code_runner'.setup { filetype = { python = 'python -u' } }
    end,
  },
  {
    'folke/trouble.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {
      focus = true,
    },
  },
  {
    'ThePrimeagen/harpoon',
    config = function()
      local opt = {
        enter_on_sendcmd = true,
      }
      if HasGoogle then
        local g = require'google'.harpoon_config()
        opt = vim.tbl_deep_extend('force', opt, g)
      end
      require'harpoon'.setup(opt)
    end,
  },
  {
    'echasnovski/mini.nvim',
    version = '*',
    config = function()
      require'mini.files'.setup {}
      require'mini.indentscope'.setup {
        draw = {
          delay = 100,
          animation = require'mini.indentscope'.gen_animation.none(),
        },
      }
    end,
  },
  { 'nvim-pack/nvim-spectre' },
} -- plugin_spec

if HasGoogle then table.insert(plugin_spec, { import = 'google-plugins' }) end

require'lazy'.setup(plugin_spec,
  { dev = { path = fn.expand('$HOME/Code/nvim-plugins') } })

if HasGoogle then Google = require'google' end

-- TODO move these into plugin config where applicable
---- Global options
g.neovide_cursor_animation_length = 0.05
g.foldlevel = 99               -- no folds on file open
g.omni_sql_no_default_maps = 1 -- disable annoying sql keymaps

vim.wo.foldlevel = 99          -- no folds on file open
vim.notify = require'notify'

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
opt.completeopt = 'menu,menuone,noselect'
opt.showmode = false
opt.scrolloff = 30 -- min number of lines to keep above and below cursor
opt.signcolumn = 'number'
opt.conceallevel = 2

-- TODO make command based and move into config, func dep on `opt.background`
---- Theme
local lualine_theme = 'solarized_light'
function SolarizedTheme(background)
  -- Docstrings should be the same color as regular comments
  vim.cmd('hi! link rustCommentLineDoc Comment')
  vim.cmd('colorscheme solarized')
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
  opt.background = background
  lualine_theme = 'gruvbox_' .. background
  cmd('colorscheme gruvbox')
end

function MaterialTheme(background) -- prefer 'deep ocean'
  if background == 'dark' then
    g.material_style = 'deep ocean'
  elseif background == 'light' then
    g.material_style = 'lighter'
  end
  lualine_theme = 'material-nvim'
  cmd('colorscheme material')
end

function RosePineTheme(background)
  opt.background = background
  lualine_theme = 'rose-pine'
  cmd('colorscheme rose-pine')
  require'rose-pine'.setup { dark_variant = 'moon', disable_italics = true }
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
  require'github-theme'.setup { theme_style = background }
end

function MelangeTheme(background)
  opt.background = background
  lualine_theme = 'auto'
  cmd('colorscheme melange')
end

function ZenbonesTheme(background)
  opt.background = background
  lualine_theme = 'auto'
  cmd('colorscheme zenbones')
end

local function fallbackTheme() RosePineTheme('light') end
local function autoTheme()
  local has_theme, theme = pcall(require, 'theme')
  if has_theme then
    theme.setup()
    return
  end
  if env.TERM == 'xterm-kitty' then
    if env.KITTY_THEME == 'solarized-light' then
      RosePineTheme('light')
    elseif env.KITTY_THEME == 'solarized-dark' then
      MaterialTheme('dark')
    else
      fallbackTheme()
    end
  elseif env.THEME == 'solarized-light' then
    RosePineTheme('light')
  else
    fallbackTheme()
  end
end
autoTheme()
vim.cmd('hi! link pythonSpaceError Normal')

local function lsp_status_component() return require'lsp-status'.status() end
require'lualine'.setup {
  options = { theme = lualine_theme, extensions = { 'quickfix', 'nvim-tree' } },
  sections = {
    lualine_x = { lsp_status_component, 'encoding', 'fileformat', 'filetype' },
  },
}

---- Keymap (note that some keys are defined in common.lua)
local map = require'common'.map
local nmap = require'common'.nmap
local imap = require'common'.imap
local vcmap = require'common'.vcmap
local ncmap = require'common'.ncmap

imap('<C-c>', '<Esc>')
nmap('<C-c>', '<Esc>')
nmap('<C-w>c', '<Nop>')
nmap('<C-w><C-c>', '<Nop>')
-- visual
map('v', '<Leader>y', '\"+y') -- copy to system clipboard
nmap('<Leader>p', '\"+p')     -- paste from system clipboard
-- g
ncmap('gfi', 'lua require"harpoon.ui".nav_file(1)')
ncmap('gfo', 'lua require"harpoon.ui".nav_file(2)')
ncmap('gfp', 'lua require"harpoon.ui".nav_file(3)')
ncmap('gff', 'lua require"harpoon.ui".toggle_quick_menu()')
ncmap('gft', 'lua require"harpoon.cmd-ui".toggle_quick_menu()')
ncmap('gfa', 'lua require"harpoon.mark".add_file()')
ncmap('gt', 'lua require"harpoon.term".gotoTerminal(1)')
ncmap('gr', 'Telescope lsp_references')
ncmap('gio', 'Telescope oldfiles')
ncmap('gii', 'Telescope lsp_implementations')
-- c
ncmap('<Leader>s', 'ChatGPT')
-- <Leader>
ncmap('<Leader>q', 'qall')
ncmap('<Leader>o', 'Telescope lsp_document_symbols')
ncmap('<Leader>O', 'Telescope lsp_dynamic_workspace_symbols')
nmap('<Leader>S', function()
  local symbols = require'symbols-outline'
  symbols.open_outline()
  fn.win_gotoid(symbols.view.winnr)
end)
ncmap('<Leader><Leader>', 'write')
-- <Leader>t    file navigation
ncmap('<Leader>tt', 'lua MiniFiles.open()')
nmap('<Leader>to', function()
  require'mini.files'.open(fn.expand('%:h'))
end)
-- <Leader>v    nvim config
ncmap('<Leader>ve', ':exe \'tabedit\' stdpath(\'config\').\'/init.lua\'')
nmap('<Leader>vs', ':exe \'source\' stdpath(\'config\').\'/init.lua\'<CR>')
-- <Leader>c    quickfix, cd
ncmap('<Leader>cl', 'cclose')
ncmap('<Leader>cc', 'cc')
ncmap('<Leader>co', 'copen')
ncmap('<Leader>cd', 'cd %:h')
-- <Leader>h    hunks + help
ncmap('<Leader>hu', 'SignifyHunkUndo')
ncmap('<Leader>hd', 'SignifyHunkDiff')
ncmap('<Leader>hh', 'Telescope help_tags')
ncmap('<Leader>hk', 'Telescope keymaps')
-- <Leader>d    debugging + diagnostics
ncmap('<Leader>dd', 'lua require"dap".toggle_breakpoint()')
ncmap('<Leader>duo', 'lua require"dapui".toggle()')
ncmap('<Leader>dt', 'lua require"dap".terminate()')
ncmap('<Leader>dc', 'lua require"dap".continue()')
ncmap('<Leader>dr', 'lua require"dap".restart()')
ncmap('<Leader>dp', 'Trouble diagnostics')
-- <Leader>w    running
ncmap('<Leader>ww', 'RunCode')
ncmap('<Leader>wc', 'RunClose')
-- <Leader>p    projects
-- reserved

-- <C-*> and <A-*>
ncmap('<C-h>', 'tabp')
ncmap('<C-l>', 'tabn')
nmap('<C-j>', '<C-e>') -- scroll one line up
nmap('<C-k>', '<C-y>') -- scroll one line down
imap('<C-v>', '<C-c>:set paste<CR>"+p:set nopaste<CR>i')
map('t', '<C-h>', '<C-\\><C-n><Cmd>:tabp<CR>')
map('t', '<C-l>', '<C-\\><C-n><Cmd>:tabn<CR>')
map('t', '<C-q>', '<C-\\><C-n><C-^>')
map('t', '<C-w><C-w>', '<C-\\><C-l><C-w>:tabn<C-w>')
map('t', '<C-\\><C-\\>', '<C-\\><C-n>')
ncmap('<C-p>', 'Telescope commands')
ncmap('<C-e>',
  'lua require"telescope.builtin".buffers({ sort_lastused = true, ignore_current_buffer = true })')
nmap('<C-q>', '<C-^>')
ncmap('<M-e>', 'Telescope find_files')
ncmap('<M-r>', 'Telescope grep_string')
ncmap('<C-e>', 'Telescope buffers')
ncmap('<M-f>', 'NvimTreeFindFile')
nmap('<M-t>', function()
  require'telescope.builtin'.find_files({
    cwd = fn.expand('%:h'),
  })
end)
ncmap('<C-w>d', 'lua OpenInRight()')
-- <F*>
ncmap('<F4>', 'Bdelete')
ncmap('<F7>', 'lua require"dap".step_into()')
ncmap('<F6>', 'lua require"dap".step_over()')

---- Util

-- Opens the current buffer in the right window and focuses it
function OpenInRight()
  local current_win = api.nvim_get_current_win()
  local wins = api.nvim_tabpage_list_wins(0)
  local current_win_pos = api.nvim_win_get_position(current_win)
  local current_win_width = api.nvim_win_get_width(current_win)
  local right_edge = current_win_pos[2] + current_win_width

  local right_win = nil
  local smallest_distance = math.huge

  for _, win in ipairs(wins) do
    if win ~= current_win then
      local win_pos = api.nvim_win_get_position(win)
      if win_pos[1] == current_win_pos[1] and win_pos[2] > current_win_pos[2] then
        local distance = win_pos[2] - right_edge
        if distance < smallest_distance then
          smallest_distance = distance
          right_win = win
        end
      end
    end
  end

  if not right_win then
    vim.notify('No right window found')
    return
  end

  local current_buf = api.nvim_win_get_buf(current_win)
  local current_pos = api.nvim_win_get_cursor(current_win)

  api.nvim_win_set_buf(right_win, current_buf)
  api.nvim_win_set_cursor(right_win, current_pos)
  api.nvim_set_current_win(right_win)
end

function Inspect(tbl) print(vim.inspect(tbl)) end

-- TODO move into lazy.nvim
if HasGoogle then Google.setup() end
