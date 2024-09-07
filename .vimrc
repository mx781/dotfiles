"General behavior settings (sets)
set number relativenumber
set scrolloff=5

set ignorecase
set smartcase 
set nohlsearch
set incsearch

set hidden
" nmap <C-l> :bn<CR>
" nmap <C-h> :bp<CR>
nmap <C-A-n> :enew<CR>
nnoremap <leader>b :ls<cr>:b<space>
tnoremap <Esc> <C-\><C-n>

set clipboard+=unnamedplus
inoremap <C-v> <C-o>:set paste<CR><C-r>+<C-o>:set paste!<CR>

set shiftwidth=4 smarttab
set expandtab
set tabstop=8 softtabstop=0
autocmd FileType typescriptreact setlocal shiftwidth=2 tabstop=2
autocmd FileType typescript setlocal shiftwidth=2 tabstop=2

set noswapfile
set nobackup

set updatetime=1500

set colorcolumn=80,120

set termguicolors

let g:mapleader=" "
" let g:python3_host_prog="/home/maksis/.pyenv/shims/python"
let g:python3_host_prog=substitute(system("which python3"), "\n", '', 'g')

"General remaps
""Shift highlighted lines around
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

""Keep cursor centered when searching
nnoremap n nzzzv
nnoremap N Nzzzv
""Show search matches
set shortmess-=S
""Toggle highlights
nnoremap <leader>h :set invhlsearch<CR>


""Paste in place (viw_p) without losing buffer
xnoremap <leader>p "_dP

""Buffers
set hidden
nmap <C-A-i> :bn<CR>
nmap <C-A-o> :bp<CR>
nmap <C-A-n> :enew<CR>
"""Rename using relative path
nnoremap <leader>rn :execute "file " . fnamemodify(expand("%"), ":~:.")<CR>:w!<CR>

""Quickfix list
nnoremap <Leader>co :copen<CR>
nnoremap <Leader>cc :cclose<CR>
nnoremap [q :cprev<CR>
nnoremap ]q :cnext<CR>

""Mouse
" no work :/
" nnoremap <X1Mouse> <C-o>
" nnoremap <X2Mouse> <C-i>

"Plugins
call plug#begin()
    Plug 'preservim/nerdtree'
  
    Plug 'junegunn/fzf'
    if has('nvim')
      Plug 'ibhagwan/fzf-lua', {'branch': 'main'}
    else
      Plug 'junegunn/fzf.vim'
    endif
  
    Plug 'catppuccin/vim', { 'as': 'catppuccin' }
    Plug 'machakann/vim-highlightedyank'
    Plug 'tpope/vim-commentary'
    Plug 'mg979/vim-visual-multi'
    Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
  
    "LSP Support
    Plug 'williamboman/mason.nvim'
    Plug 'williamboman/mason-lspconfig.nvim'
    Plug 'neovim/nvim-lspconfig'

    " Plug 'dense-analysis/ale'

    "Autocompletion
    Plug 'hrsh7th/nvim-cmp'
    Plug 'hrsh7th/cmp-nvim-lsp'
    Plug 'L3MON4D3/LuaSnip'
    Plug 'VonHeikemen/lsp-zero.nvim', {'branch': 'v3.x'}

    Plug 'github/copilot.vim'

    "Refactoring
    " Plug 'python-rope/ropevim'

    "Navigation
    Plug 'ggandor/leap.nvim'

    "Jupyter
    Plug 'untitled-ai/jupyter_ascending.vim'
    Plug 'benlubas/molten-nvim'

    "Git
    Plug 'tpope/vim-fugitive'
call plug#end()

"Plugin configs and remaps 
""NERDTree
nnoremap <leader>n :NERDTreeFocus<CR>
" nnoremap <C-n> :NERDTree<CR>
nnoremap <C-t> :NERDTreeToggle<CR>
nnoremap <leader>f :NERDTreeFind<CR>

"""Start NERDTree and put the cursor back in the other window.
autocmd VimEnter * NERDTree | wincmd p

"""Exit Vim if NERDTree is the only window remaining in the only tab.
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif

" Open the existing NERDTree on each new tab.
" autocmd BufWinEnter * if &buftype != 'quickfix' && getcmdwintype() == '' | silent NERDTreeMirror | endif

""fzf
if has('nvim')
  nmap <C-f> :FzfLua grep<cr>
  nmap <C-p> :FzfLua files<cr> 
  nmap <C-b> :FzfLua buffers<cr>
  nmap <C-s> :FzfLua lsp_live_workspace_symbols<cr>
else
  nmap <C-f> :Rg<cr>
  nmap <C-p> :GFiles<cr>
  nmap <C-A-p> :Files<cr>
  nmap <C-b> :Buffers<cr>
endif


""colors
if has('nvim')
  colorscheme catppuccin_mocha
else
  colorscheme habamax
endif

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

"" undo/redo
""" {} not in jumplist
nnoremap <silent> } :<C-u>execute "keepjumps norm! " . v:count1 . "}"<CR>
nnoremap <silent> { :<C-u>execute "keepjumps norm! " . v:count1 . "{"<CR>

"" windows
""" resize windows
nnoremap <A-L> 5<C-w>>
nnoremap <A-H> 5<C-w><
nnoremap <A-J> 5<C-w>+
nnoremap <A-K> 5<C-w>-

""" move between windows
nnoremap <A-l> <C-w>l
nnoremap <A-h> <C-w>h
nnoremap <A-j> <C-w>j
nnoremap <A-k> <C-w>k

""" close window
nnoremap <A-c> <C-w>c

""Autocompletion
"""Auto-import
nmap <C-a> eli<C-n><C-n>

""Jupyter Ascending
nmap <leader>x :call jupyter_ascending#sync()<cr><Plug>JupyterExecute
let g:jupyter_ascending_auto_write = v:false

""Notebooks, a la mx (with inspiration from ov and qq)
let g:cell = "^# \\?%%\s*$"
nmap <leader>mz o# %%<cr><esc>
nmap <leader>ma O# %%<cr><esc>

function! SearchAndJump(pattern, direction, defaultAction)
  let l:line = search(a:pattern, a:direction)
  if l:line != 0
    silent execute "normal! " . l:line . "G"
  else
    silent execute "normal! " . a:defaultAction
  endif
endfunction
nnoremap <silent> { :call SearchAndJump(g:cell, 'bW', '{')<cr>
nnoremap <silent> } :call SearchAndJump(g:cell, 'W', '}')<cr>

function! Cell()
  let g:saved_cursor = getpos('.')
  normal! l
  let l:startPos = search(g:cell, 'bW')
  let l:endPos = search(g:cell, 'W')
  if l:startPos > 0
    echomsg l:endPos
    if l:endPos == 0
      let l:endPos = line('$') + 1
    endif
    " Exclude the cell marker
    let l:startPos = l:startPos + 1
    call cursor(l:startPos, 1)
    normal! v
    call cursor(l:endPos - 1, 1)
    normal! $
  endif
endfunction

function! GetFileNotebookSession()
    let l:project = fnamemodify(getcwd(), ":t")
    let l:file = expand("%:t:r")
    return l:project . "/" . l:file
endfunction

function! MakeFileNotebook()
    let l:session = GetFileNotebookSession()
    call system("tmux new-session -d -s " . l:session)
    let l:venv = trim(system("echo $VIRTUAL_ENV"))
    call system("tmux send-keys -t " . l:session . " 'source " . l:venv . "/bin/activate' ENTER")
    call system("tmux send-keys -t " . l:session . " 'ipython' ENTER")
endfunction

function! OpenFileNotebook()
    let l:session = GetFileNotebookSession()
    execute 'vsplit'
    execute 'wincmd w'
    execute 'terminal'
    execute 'startinsert'
    call feedkeys("tmux attach-session -t " . l:session . "\<CR>\<Esc>\<C-w>w", 't')
endfunction

function! RunCell()
  call Cell()
  normal! "+y

  "Remove comment marker before magics (so python file can be valid syntax)
  let l:lines = split(@+, "\n")
  let l:modified_lines = map(l:lines, 'substitute(v:val, "^# %", "%", "")')
  let @+ = join(l:modified_lines, "\n")

  call feedkeys("\<C-w>l")
  call feedkeys("\"+pA\<CR>\<CR>")
  call feedkeys("\<Esc>\<C-w>h")
endfunction

command! MakeFileNotebook :call MakeFileNotebook()
command! OpenFileNotebook :call OpenFileNotebook()

nnoremap <silent> <leader><cr> :call RunCell()<cr>:call setpos('.', g:saved_cursor)<cr>
nnoremap <silent> <leader><s-cr> :call RunCell()<cr>:call search(g:cell, 'W')<cr>

""Mini-plugins
:command! -range Encrypt :'<,'>!gpg -ca --s2k-count 65011712
:command! -range Decrypt :'<,'>!gpg -dq

hi default BookmarkCol ctermfg=blue ctermbg=lightblue cterm=bold guifg=DarkBlue guibg=#d0d0ff gui=bold
sign define MyBookmark linehl=BookmarkCol
nnoremap <leader>ba :exe 'sign place ' . line('.') . ' name=MyBookmark line=' . line(".") . ' buffer='.winbufnr(0)<CR>
nnoremap <leader>bd :exec 'sign unplace ' . line('.')<CR>
nnoremap <leader>bl :sign list<CR>

"Project-specific settings
silent! so .vimlocal

