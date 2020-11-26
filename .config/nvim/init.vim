if filereadable(stdpath('config').'/google.vim')
  exe 'source' stdpath('config').'/google.vim'
endif

call plug#begin(stdpath('data').'/plugged')

Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'sheerun/vim-polyglot'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'lifepillar/vim-solarized8'
Plug 'scrooloose/nerdtree'
Plug 'tpope/vim-commentary'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

call plug#end()

" CoC set up
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <silent> gy <Plug>(coc-type-definition)

nnoremap <silent> K :call CocAction('doHover')<CR>


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
inoremap <expr> <CR> pumvisible() ? "\<C-n>" : "\<C-g>u\<CR>"

" init.vim
nmap <Leader>v :exe 'tabedit' stdpath('config').'/init.vim'<CR>
nmap <Leader>s :exe 'source' stdpath('config').'/init.vim'<CR>

nmap <C-h> :tabp<CR>
nmap <C-l> :tabn<CR>
nmap <C-e> :Buffers<CR>
nmap <C-A-e> :Files<CR>

nmap <A-1> :NERDTreeToggle<CR>

augroup rust_group
  au!
  au FileType rust nmap <F10> :RustRun<CR>
  au FileType rust nmap <F11> :RustTest<CR>
  "<F23> == <S-F11> in kitty
  au FileType rust nmap <F23> :RustTest!<CR>
  au FileType rust nmap <C-A-l> :RustFmt<CR>
augroup END

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

set background=light
colorscheme solarized8
let g:airline_theme='solarized'

filetype plugin indent on
