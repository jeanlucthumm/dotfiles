if filereadable(stdpath('config').'/google.vim') 
  exe 'source' stdpath('config').'/google.vim'
endif

call plug#begin(stdpath('data').'/plugged')

Plug 'neoclide/coc.nvim', {'branch': 'release', 'do': 'yarn install --frozen-lockfile'}
Plug 'antoinemadec/coc-fzf'
Plug 'sheerun/vim-polyglot'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'scrooloose/nerdtree'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-dispatch'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'jiangmiao/auto-pairs'
Plug 'neomake/neomake'
Plug '907th/vim-auto-save'
Plug 'airblade/vim-gitgutter'
Plug 'vim-test/vim-test'
Plug 'sakhnik/nvim-gdb', { 'do': ':!./install.sh' }
Plug 'moll/vim-bbye'
Plug 'andrejlevkovitch/vim-lua-format'
Plug 'pseewald/vim-anyfold'
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn install'  }
Plug 'MattesGroeger/vim-bookmarks'

Plug 'jeanlucthumm/vim-solarized8'
Plug 'morhetz/gruvbox'

call plug#end()

nnoremap <Space> <Nop>
let mapleader = "\<Space>"

" CoC set up
command! -nargs=? Fold :call CocAction('fold', <f-args>)
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> <Leader>a v<Plug>(coc-codeaction-selected)<C-C>
nmap <silent> <F2> <Plug>(coc-diagnostic-next)
nmap <silent> <Leader>r <Plug>(coc-rename)
nnoremap <silent> K :call CocAction('doHover')<CR>
nmap <silent> <Leader>o :CocFzfList outline<CR>
nmap <silent> <Leader>O :CocFzfList symbols<CR>
nmap <silent> <Leader>d :CocFzfList diagnostics<CR>
nmap <silent> <Leader>f :call CocAction('format')<CR>



" Use tab and space for autocompletion
function! s:check_back_space() abort
  let col = col('.') - 1 
  return !col || getline('.')[col - 1]  =~ '\s'
endfunction
inoremap <silent><expr> <Tab>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<Tab>" :
      \ coc#refresh()
inoremap <silent><expr> <C-Space> coc#refresh()
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
inoremap <expr> <CR> 
      \ pumvisible() ? (empty(v:completed_item)?"\<C-n>":"\<C-g>u\<CR>") : 
      \ "\<C-g>u\<CR>"


" init.vim
nmap <Leader>ve :exe 'tabedit' stdpath('config').'/init.vim'<CR>
nmap <Leader>vs :exe 'source' stdpath('config').'/init.vim'<CR>
" yes I'm lazy
nmap <silent> <Leader><Leader> :write<CR>
nmap <Leader>q :qall<CR>
" quickfix
nmap <Leader>cl :cclose<CR>
nmap <Leader>cc :cc<CR>
nmap <Leader>co :copen<CR>

nmap <Leader>bb :BookmarkToggle<CR>
nmap <Leader>ba :BookmarkAnnotate<CR>
nmap <Leader>bo :BookmarkShowAll<CR>

nmap <C-h> :tabp<CR>
nmap <C-l> :tabn<CR>
nmap <S-h> <C-w>h
nmap <S-l> <C-w>l
tnoremap <C-h> <C-\><C-n>:tabp<CR>
tnoremap <C-l> <C-\><C-n>:tabn<CR>
nmap <silent> <C-e> :Buffers<CR>
nmap <silent> <C-A-e> :Files<CR>
nmap <A-1> :NERDTreeToggle<CR>
nmap gt :tabe<CR>:term<CR>i
nmap <F4> :Bdelete<CR>

set tabstop=2
set shiftwidth=2
set expandtab
set number
if has('nvim-0.5.0')
  set signcolumn=number
endif
set termguicolors
set splitright
set hidden
set mouse=a
set updatetime=500
" preserve undo history
"set undodir='~/.vimdid'
"set undofile
let g:neomake_open_list=2
let g:auto_save=0
let g:auto_save_events=["InsertLeave", "TextChanged", "CursorHold"]
let g:nvimgdb_disable_start_keymaps=1
" so that pynvim uses the right python
let g:python3_host_prog="~/Code/venv/neovim/bin/python"
let test#strategy = 'neomake'

" Neovide
set guifont=Fira\ Code:h11
let g:neovide_cursor_animation_length=0.05

function! SolarizedTheme()
  let g:airline_theme='solarized'
  hi! link rustCommentLineDoc Comment
  colorscheme solarized8
endfunction

function! GruvboxTheme()
  let g:gruvbox_italic=1
  let g:gruvbox_bold=1
  let g:airline_theme='gruvbox'
  let $BAT_THEME='gruvbox'
  colorscheme gruvbox
endfunction

hi! link pythonSpaceError Normal
set background=light
call SolarizedTheme()

" Gives the ighlight groups under the cursor
function! HighlightGroups()
  for id in synstack(line("."), col("."))
    echo synIDattr(id, "name")
  endfor
endfunction
command! -nargs=0 HighlightGroups call HighlightGroups()


" On startup, vim will look for a .session.vim file in the current
" directory and load it if one exists. Use :mks .session.vim to save a new one.
function! SourceSession()
  if filereadable('.session.vim')
    exe 'source' '.session.vim'
  endif
endfunction

augroup std_group
  au!
  " Resize panes to equal splits when resizing window
  au VimResized * wincmd =
  au VimEnter * nested call SourceSession()
augroup END

augroup rust_group
  au!
  au FileType rust nmap <F10> :w<CR>:Neomake! cargo<CR>
  au FileType rust map t <Nop>
  au FileType rust nnoremap tn :TestNearest<CR>
  au FileType rust nnoremap tl :TestLast<CR>
  au FileType rust nnoremap tf :TestFile<CR>
  " <F23> == <S-F11> in kitty
  au FileType rust nmap <F23> :RustTest!<CR>
  au FileType rust let g:auto_save=1
  au CursorHold *.rs silent call CocActionAsync('highlight')
augroup END

augroup lua_group
  au!
  au FileType lua nmap <F10> :Neomake<CR>
  au FileType lua nmap <Leader>f :call LuaFormat()<CR>
  au FileType lua let g:auto_save=1
  au CursorHold *.lua silent call CocActionAsync('highlight')
  au FileType lua nmap <Leader>cl :lclose<CR>
  au FileType lua nmap <Leader>cc :ll<CR>
  au FileType lua nmap <Leader>co :lopen<CR>
  au FileType lua nmap <F11> :!lua %<CR>
augroup END

augroup python_group
  au!
  au FileType python let g:auto_save=1
  au FileType python nmap <F5> :!python '%'<CR>
augroup END

augroup dart_group
  au!
  au FileType dart let g:auto_save=1
augroup END


filetype plugin indent on

