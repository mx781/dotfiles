"General behavior settings (sets)
set number relativenumber
set scrolloff=5

set smartcase 
set nohlsearch
set incsearch

set hidden
" nmap <C-l> :bn<CR>
" nmap <C-h> :bp<CR>
nmap <C-A-n> :enew<CR>
nnoremap <leader>b :ls<cr>:b<space>

set clipboard+=unnamedplus
inoremap <C-v> <C-o>:set paste<CR><C-r>+<C-o>:set paste!<CR>

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

""Buffers
set hidden
" nmap <C-l> :bn<CR>
" nmap <C-h> :bp<CR>
nmap <C-A-n> :enew<CR>

""Quickfix list
nnoremap <Leader>co :copen<CR>
nnoremap <Leader>cc :cclose<CR>
nnoremap [q :cprev<CR>
nnoremap ]q :cnext<CR>

"Plugins
call plug#begin()
    Plug 'preservim/nerdtree'
  
    Plug 'junegunn/fzf'
    " Plug 'junegunn/fzf.vim'
    Plug 'ibhagwan/fzf-lua', {'branch': 'main'}
  
    Plug 'catppuccin/vim', { 'as': 'catppuccin' }
    Plug 'machakann/vim-highlightedyank'
    Plug 'tpope/vim-commentary'
    Plug 'mg979/vim-visual-multi'
    Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
  
    " LSP Support
    Plug 'williamboman/mason.nvim'
    Plug 'williamboman/mason-lspconfig.nvim'
    Plug 'neovim/nvim-lspconfig'

    " Autocompletion
    Plug 'hrsh7th/nvim-cmp'
    Plug 'hrsh7th/cmp-nvim-lsp'
    Plug 'L3MON4D3/LuaSnip'
    
    Plug 'VonHeikemen/lsp-zero.nvim', {'branch': 'v3.x'}
call plug#end()

"Plugin configs and remaps 
""NERDTree
nnoremap <leader>n :NERDTreeFocus<CR>
" nnoremap <C-n> :NERDTree<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
" nnoremap <C-f> :NERDTreeFind<CR>

"""Start NERDTree and put the cursor back in the other window.
autocmd VimEnter * NERDTree | wincmd p

"""Exit Vim if NERDTree is the only window remaining in the only tab.
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

" Open the existing NERDTree on each new tab.
" autocmd BufWinEnter * if &buftype != 'quickfix' && getcmdwintype() == '' | silent NERDTreeMirror | endif

""fzf
nmap <C-f> :FzfLua grep<cr>
nmap <C-p> :FzfLua git_files<cr> 
nmap <C-A-p> :FzfLua files<cr>
nmap <leader>b :FzfLua buffers<cr>
nmap <C-s> :FzfLua lsp_live_workspace_symbols<cr>


""colors
colorscheme catppuccin_mocha

""highlightedyank
let g:highlightedyank_highlight_duration = 350

""Commentary
"""Comment out line(s) (C-_ maps ctrl+slash)
nmap <C-_> gc$
vmap <C-_> gc$

""Treesitter/folding
set foldmethod=expr
set foldexpr=nvim_treesitter#foldexpr()
set nofoldenable 

""Autocompletion
"""Auto-import
nmap <C-a> wi<C-n><C-n>
