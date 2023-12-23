"General behavior settings (sets)
set number relativenumber
set scrolloff=5

set smartcase 
set nohlsearch
set incsearch

set clipboard+=unnamedplus
set pastetoggle=<F10>
"todo: doesn't work
inoremap <C-v> <F10><C-r>+<F10>

set shiftwidth=4 smarttab
set expandtab
set tabstop=8 softtabstop=0

set noswapfile
set nobackup

set updatetime=1500

set colorcolumn=80,120

set termguicolors

let g:mapleader=" "

"General remaps
""Shift highlighted lines around
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

""Keep cursor centered when searching
nnoremap n nzzzv
nnoremap N Nzzzv

""Paste in place (viw_p) without losing buffer
xnoremap <leader>p "_dP

"Plugins
call plug#begin()
  Plug 'preservim/nerdtree'
  Plug 'junegunn/fzf'
  Plug 'junegunn/fzf.vim'
  Plug 'catppuccin/vim', { 'as': 'catppuccin' }
  Plug 'machakann/vim-highlightedyank'
  Plug 'tpope/vim-commentary'
  Plug 'mg979/vim-visual-multi'
  Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
call plug#end()

"Plugin configs and remaps 
""NERDTree
nnoremap <leader>n :NERDTreeFocus<CR>
" nnoremap <C-n> :NERDTree<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
nnoremap <C-f> :NERDTreeFind<CR>

"""Start NERDTree and put the cursor back in the other window.
autocmd VimEnter * NERDTree | wincmd p

"""Exit Vim if NERDTree is the only window remaining in the only tab.
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

""fzf
map <C-p> :Files<cr> 

""highlightedyank
let g:highlighteuyank_highlight_duration = 350 

""Commentary
"""Comment out line(s) (C-_ maps ctrl+slash)
nmap <C-_> gc$
vmap <C-_> gc$

