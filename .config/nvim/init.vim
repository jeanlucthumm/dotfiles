if $TERM != 'xterm-kitty'
  finish 
endif

if filereadable(stdpath('config').'/google.vim')
  exe 'source' stdpath('config').'/google.vim'
endif

call plug#begin(stdpath('data').'/plugged')

Plug 'neoclide/coc.nvim', {'branch': 'release', 'do': 'yarn install --frozen-lockfile'}
Plug 'antoinemadec/coc-fzf'
Plug 'sheerun/vim-polyglot'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'lifepillar/vim-solarized8'
Plug 'scrooloose/nerdtree'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-dispatch'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'jiangmiao/auto-pairs'
Plug 'neomake/neomake'
Plug '907th/vim-auto-save'
" Plug 'airblade/vim-rooter'
Plug 'airblade/vim-gitgutter'
Plug 'vim-test/vim-test'
Plug 'dbgx/lldb.nvim'

call plug#end()

nnoremap <Space> <Nop>
let mapleader = "\<Space>"

" CoC set up
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <Leader>a v<Plug>(coc-codeaction-selected)<C-C>
nmap <silent> <F2> <Plug>(coc-diagnostic-next)
nmap <silent> <Leader>r <Plug>(coc-rename)
nnoremap <silent> K :call CocAction('doHover')<CR>
nmap <Leader>o :CocFzfList outline<CR>
nmap <Leader>O :CocFzfList symbols<CR>
nmap <Leader>d :CocFzfList diagnostics<CR>



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
nmap <Leader><Leader> :write<CR>
nmap <Leader>q :qall<CR>
" quickfix
nmap <Leader>cl :cclose<CR>
nmap <Leader>cc :cc<CR>
nmap <Leader>co :copen<CR>

nmap <C-h> :tabp<CR>
nmap <C-l> :tabn<CR>
nmap <S-h> <C-w>h
nmap <S-l> <C-w>l
tnoremap <C-h> <C-\><C-n>:tabp<CR>
tnoremap <C-l> <C-\><C-n>:tabn<CR>
nmap <C-A-e> :Buffers<CR>
nmap <C-e> :Files<CR>
nmap <A-1> :NERDTreeToggle<CR>
nmap gt :tabe<CR>:term<CR>i

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
set updatetime=1000
" preserve undo history
"set undodir='~/.vimdid'
"set undofile
let g:airline_theme='solarized'
let g:neomake_open_list=2
let g:auto_save=0
let g:auto_save_events=["InsertLeave", "TextChanged", "CursorHold"]
let test#strategy = 'neomake'

set background=light
colorscheme solarized8
highlight CocUnderline cterm=NONE gui=NONE guibg=#fde2e2

augroup std_group
  au!
  " Resize panes to equal splits when resizing window
  au VimResized * wincmd =
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
  au FileType rust nmap <Leader>f :RustFmt<CR>
  au FileType rust let g:auto_save=1
  au CursorHold *.rs silent call CocActionAsync('highlight')
augroup END

" On startup, vim will look for a .session.vim file in the current
" directory and load it if one exists. Use :mks .session.vim to save a new one.
function! SourceSession()
  if filereadable('.session.vim')
    exe 'source' '.session.vim'
  endif
endfunction

filetype plugin indent on

augroup vim_group
  au!
  au VimEnter * nested call SourceSession()
augroup END
