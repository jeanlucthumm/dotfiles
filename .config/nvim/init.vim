if filereadable(stdpath('config').'/google.vim')
  exe 'source' stdpath('config').'/google.vim'
endif

call plug#begin(stdpath('data').'/plugged')

Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'sheerun/vim-polyglot'
Plug 'junegunn/fzf.vim'

Plug 'lifepillar/vim-solarized8'
Plug 'sickill/vim-monokai'

call plug#end()

" CoC set up
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" use tab and space for autocompletion
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
inoremap <expr> <CR> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"

nmap <Leader>v :exe 'tabedit' stdpath('config').'/init.vim'<CR>
nmap <Leader>s :exe 'source' stdpath('config').'/init.vim'<CR>

nmap <C-h> :tabp<CR>
nmap <C-l> :tabn<CR>
nmap <C-e> :Buffers<CR>

set tabstop=2
set shiftwidth=2
set expandtab
set number
"set signcolumn=number
set termguicolors
set splitright

set background=dark
colorscheme solarized8

filetype plugin indent on
