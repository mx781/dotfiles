"General behavior settings (sets)
set exrc
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
" F1 in terminal code = ESC for apps that need it
tnoremap <F1> <Esc>
" F1 is always a typo for esc
inoremap <F1> <Esc>

set clipboard+=unnamedplus
inoremap <C-v> <C-o>:set paste<CR><C-r>+<C-o>:set paste!<CR>

set shiftwidth=4 smarttab
set expandtab
set tabstop=8 softtabstop=0
autocmd FileType typescriptreact setlocal shiftwidth=2 tabstop=2
autocmd FileType typescript setlocal shiftwidth=2 tabstop=2
autocmd FileType markdown setlocal shiftwidth=2 tabstop=2


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

    "Other syntax highlighting
    Plug 'Glench/Vim-Jinja2-Syntax'
    Plug 'rust-lang/rust.vim'
  
    "LSP Support
    Plug 'williamboman/mason.nvim'
    Plug 'williamboman/mason-lspconfig.nvim'
    Plug 'neovim/nvim-lspconfig'

    " Plug 'dense-analysis/ale'
    "Debugging
    Plug 'mfussenegger/nvim-dap'

    "Autocompletion
    Plug 'hrsh7th/nvim-cmp'
    Plug 'hrsh7th/cmp-nvim-lsp'
    Plug 'L3MON4D3/LuaSnip'
    " Plug 'VonHeikemen/lsp-zero.nvim', {'branch': 'v3.x'}

    """Optional deps
    " Plug 'hrsh7th/nvim-cmp'
    Plug 'nvim-tree/nvim-web-devicons' "or Plug 'echasnovski/mini.icons'
    Plug 'HakonHarnes/img-clip.nvim'
    " Plug 'zbirenbaum/copilot.lua'

    "Refactoring
    " Plug 'python-rope/ropevim'

    "Navigation
    Plug 'https://codeberg.org/andyg/leap.nvim'

    "Jupyter
    Plug 'untitled-ai/jupyter_ascending.vim'

    "Git
    Plug 'tpope/vim-fugitive'

    "Obsidian
    Plug 'nvim-lua/plenary.nvim'
    Plug 'epwalsh/obsidian.nvim'
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
"""Comment out line(s)
""""Most terminals send <C-_> for ctrl+slash; newer nvim sends <C-/>. Bind both.
nmap <C-_> gc$
vmap <C-_> gc$
nmap <C-/> gc$
vmap <C-/> gc$

""Obsidian
"""Allow for markdown preview (checked boxes)
autocmd FileType md setlocal conceallevel=1

""Treesitter/folding
set foldmethod=expr
set foldexpr=nvim_treesitter#foldexpr()
set nofoldenable 

""Copilot
let g:copilot_filetypes = {
\ 'markdown': v:false,
\ 'md': v:false,
\ }

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
" let g:cell = "^# \\?%%\s*$"
" Matches '# %%' plus any trailing metadata jupytext/colab emits, e.g.
" '# %% [markdown]' or '# %% id="-Xbb0cuLzwgf"'
let g:cell = '^# \?%%\( .*\)\?$'
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
    let l:venv = trim(system("echo $VIRTUAL_ENV"))
    " call system("mkdir -p /tmp/dtach/" . l:session)
    " call system("dtach -n /tmp/dtach/" . l:session . "/session bash -c 'source " . l:venv . "/bin/activate; while true; do ipython; done'")
    call system("tmux set-option -g history-limit 50000 \\; new-session -d -s " . l:session)
    call system("tmux send-keys -t " . l:session . " 'source " . l:venv . "/bin/activate' ENTER")
    call system("tmux send-keys -t " . l:session . " 'while true; do ipython; done' ENTER")
endfunction

function! OpenFileNotebook()
    let l:session = GetFileNotebookSession()
    execute 'vsplit'
    execute 'wincmd w'
    execute 'terminal'
    execute 'startinsert'
    call feedkeys("tmux attach-session -t " . l:session . "\<CR>\<Esc>\<C-w>w", 't')
    " call feedkeys("dtach -a /tmp/dtach/" . l:session . "/session\<CR>\<Esc>\<C-w>w", 't')
endfunction

function! FileNotebook()
  call MakeFileNotebook()
  call OpenFileNotebook()
endfunction

function! TmuxWorkspace()
    let l:session = GetFileNotebookSession()
    execute 'vsplit'
    execute 'wincmd w'
    execute 'terminal'
    execute 'startinsert'
    call feedkeys("tmux a\<CR>\<Esc>\<C-w>w", 't')
endfunction


function! Sesh(session)
    execute 'vsplit'
    execute 'wincmd w'
    execute 'terminal'
    execute 'startinsert'
    " -A: attach if the session exists, otherwise create it
    call feedkeys("tmux new-session -A -s " . shellescape(a:session) . "\<CR>", 't')
endfunction

command! MakeFileNotebook :call MakeFileNotebook()
command! OpenFileNotebook :call OpenFileNotebook()
command! FileNotebook :call FileNotebook()
command! TmuxWorkspace :call TmuxWorkspace()
command! -nargs=1 Sesh :call Sesh(<q-args>)

function! RunSelection() range
  execute a:firstline . ',' . a:lastline . 'y +'

  "Remove comment marker before magics (so python file can be valid syntax)
  let l:lines = split(@+, "\n")
  let l:modified_lines = map(l:lines, 'substitute(v:val, "^# %", "%", "")')
  let l:modified_lines = map(l:modified_lines, 'substitute(v:val, "^# !", "!", "")')
  let @+ = join(l:modified_lines, "\n")

  call feedkeys("\<C-w>l")
  call feedkeys("\"+pA\<CR>\<CR>")
  call feedkeys("\<Esc>\<C-w>h")
endfunction

nnoremap <silent> <leader><cr> :call Cell()<cr>:call RunSelection()<cr>:call setpos('.', g:saved_cursor)<cr>
nnoremap <silent> <leader><s-cr> :call Cell()<cr>:call RunSelection()<cr>:call search(g:cell, 'W')<cr>
vnoremap <silent> <leader><cr> :call RunSelection()<cr>:call setpos('.', g:saved_cursor)<cr>

nnoremap <silent> <C-s> <Esc><C-w>lA
inoremap <silent> <C-s> <Esc><C-w>lA
tnoremap <silent> <C-s> <C-\><C-n><C-w>h

""Rust: switch, run, switch back
function! RunInSidePanel()
    " Save the current file
    if &modified
        write
    endif
    call feedkeys("\<C-w>l")
    call feedkeys("iclear\&\&cargo run\<CR>")
    call feedkeys("\<Esc>\<C-w>h")
endfunction
command! RunInSidePanel call RunInSidePanel()
nnoremap <silent> <leader>rr :call RunInSidePanel()<CR>


""Mini-plugins
"""trim whitespace
xnoremap <leader>tw :<C-u>keeppatterns '<,'>s/^\s*\(.\{-}\)\s*$/\1/e<CR>gv
:command! -range Encrypt :'<,'>!gpg -ca --s2k-count 65011712
:command! -range Decrypt :'<,'>!gpg -dq

nnoremap <leader>rf :!ruff format %<CR>:e!<CR>
nnoremap <leader>rl :!ruff check --fix %<CR>
command! -range Ruff :!ruff format % --range <line1>-<line2>

hi default BookmarkCol ctermfg=blue ctermbg=lightblue cterm=bold guifg=DarkBlue guibg=#d0d0ff gui=bold
sign define MyBookmark linehl=BookmarkCol
nnoremap <leader>ba :exe 'sign place ' . line('.') . ' name=MyBookmark line=' . line(".") . ' buffer='.winbufnr(0)<CR>
nnoremap <leader>bd :exec 'sign unplace ' . line('.')<CR>
nnoremap <leader>bl :sign list<CR>

" Nearest ancestor of {path} containing a .obsidian directory, i.e. the vault
" root that bare wikilinks resolve against. Falls back to the directory
" containing {path} when there is no vault.
fun! NFH_vault_root(path) abort
  let l:dir = fnamemodify(a:path, ':p:h')
  let l:marker = finddir('.obsidian', l:dir . ';')
  if empty(l:marker)
    return l:dir
  endif
  " strip the trailing slash fnamemodify(':p') puts on directories, so a
  " single ':h' reliably drops the .obsidian component itself
  let l:marker = substitute(fnamemodify(l:marker, ':p'), '/\+$', '', '')
  return fnamemodify(l:marker, ':h')
endfun

" Resolve a wikilink target to an absolute path the way Obsidian does:
" alongside the note first, then vault-root-relative, then the attachment
" folder. Returns '' when nothing matches.
fun! NFH_resolve_link(target, note) abort
  let l:root = NFH_vault_root(a:note)
  let l:candidates = [
    \ fnamemodify(a:note, ':p:h') . '/' . a:target,
    \ l:root . '/' . a:target,
    \ l:root . '/attachments/' . a:target,
    \ ]
  for l:candidate in l:candidates
    if filereadable(l:candidate)
      return l:candidate
    endif
  endfor
  return ''
endfun

let g:NFH_image_extensions = ['png', 'jpg', 'jpeg', 'gif', 'webp', 'svg', 'bmp', 'avif', 'tif', 'tiff']

fun! NFH_is_image(target) abort
  return index(g:NFH_image_extensions, tolower(fnamemodify(a:target, ':e'))) >= 0
endfun

" Open {paths} in a single feh instance; the action key copies the real path of
" the displayed image to the clipboard.
fun! NFH_feh(paths) abort
  let l:cmd = 'feh -B ' . shellescape('#999999')
    \ . ' -A ' . shellescape(';realpath "%F" | xclip -selection clipboard')
    \ . ' ' . join(map(copy(a:paths), 'shellescape(v:val)'), ' ') . ' &'
  call system(l:cmd)
endfun

" The wikilink target under the cursor, or '' when the cursor is not inside a
" [[link]] / ![[embed]]. Anchors and |aliases are stripped.
fun! NFH_link_under_cursor() abort
  let l:line = getline('.')
  let l:col = col('.')
  let l:start = 0
  while 1
    let [l:match, l:from, l:to] = matchstrpos(l:line, '!\?\[\[[^]]\+\]\]', l:start)
    if l:from < 0
      return ''
    endif
    " matchstrpos gives 0-based byte offsets, col('.') is 1-based
    if l:col > l:from && l:col <= l:to
      return substitute(matchstr(l:match, '\[\[\zs[^]|#]\+'), '^\s\+\|\s\+$', '', 'g')
    endif
    let l:start = l:to
  endwhile
endfun

" gx for notes: an image wikilink under the cursor opens in feh, anything else
" falls through to the normal system handler so plain URLs keep working.
fun! NFH_gx() abort
  let l:target = NFH_link_under_cursor()
  if !empty(l:target) && NFH_is_image(l:target)
    let l:path = NFH_resolve_link(l:target, expand('%:p'))
    if empty(l:path)
      echohl WarningMsg
      echom 'gx: unresolved link: ' . l:target
      echohl None
      return
    endif
    call NFH_feh([l:path])
    return
  endif

  " same target expression Neovim's built-in gx and netrw's both use
  let l:cfile = expand('<cfile>')
  if empty(l:cfile)
    return
  endif
  if has('nvim')
    call v:lua.vim.ui.open(l:cfile)
  elseif exists('*netrw#BrowseX')
    call netrw#BrowseX(l:cfile, netrw#CheckIfRemote(l:cfile))
  endif
endfun

augroup NFHNoteMappings
  autocmd!
  autocmd FileType markdown nnoremap <buffer> <silent> gx :call NFH_gx()<CR>
augroup END

fun! NFH_note_pngs() abort
  let l:note = expand('%:p')
  let l:pattern = '!\[\[([^]|#]+)(?:#[^]|]*)?(?:\|[^]]*)?\]\]'
  let l:targets = systemlist('rg -o --no-filename --replace ' . shellescape('$1')
    \ . ' ' . shellescape(l:pattern) . ' ' . shellescape(l:note))

  let l:paths = []
  let l:missing = []
  for l:raw in l:targets
    let l:target = substitute(l:raw, '^\s\+\|\s\+$', '', 'g')
    " skip note transclusions and anything feh cannot display
    if empty(l:target) || !NFH_is_image(l:target)
      continue
    endif
    let l:path = NFH_resolve_link(l:target, l:note)
    if empty(l:path)
      call add(l:missing, l:target)
    else
      call add(l:paths, l:path)
    endif
  endfor

  if !empty(l:missing)
    echohl WarningMsg
    echom 'NFHNotePngs: unresolved ' . len(l:missing) . ' link(s): ' . join(l:missing[:4], ', ')
    echohl None
  endif

  if empty(l:paths)
    echohl WarningMsg
    echom 'NFHNotePngs: no viewable images in this note'
    echohl None
    return
  endif

  call NFH_feh(l:paths)
endfun
command! NFHNotePngs call NFH_note_pngs()
nnoremap <silent> gX :call NFH_note_pngs()<CR>

let g:netrw_browsex_viewer = '-'


nnoremap <silent> p :call NotemasterPaste()<cr>

" Images always land in <vault root>/attachments and are linked bare, i.e.
" '![[pasted_image_9.png]]', matching how the vast majority of the notes are
" written and how Obsidian itself pastes. The path is derived from the note
" being edited, never from the cwd, so pasting from a subdirectory does not
" strand the file in a nested attachments/ dir.

function! NotemasterPaste() abort
  let targets = filter(
      \ systemlist('xclip -selection clipboard -t TARGETS -o'),
      \ 'v:val =~# ''image''')

  " only treat this as an image paste if the clipboard offers a subtype we can
  " actually name a file after; junk like image/x-qt-image is not usable.
  let mimetype = ''
  for candidate in targets
    if index(g:NFH_image_extensions, tolower(split(candidate, '/')[-1])) >= 0
      let mimetype = candidate
      if candidate ==# 'image/png'
        break
      endif
    endif
  endfor

  if empty(mimetype)
    let reg_specifier = v:register
    let cmd = 'normal! "' . reg_specifier . 'p'
    execute cmd
    return
  endif

  " if we get this far, we're pasting an image -> want to do in new line
  " always.
  execute "normal! o\<Esc>"

  let outdir = NFH_vault_root(expand('%:p')) . '/attachments'
  if !isdirectory(outdir)
    call mkdir(outdir, 'p')
  endif

  let extension = split(mimetype, '/')[-1]

  let filename_no_extension = system('find ' . shellescape(outdir) . ' -name "pasted_image_*" -printf "%f\n" | sort -V | tail -n -1 | sed -E ''s/(pasted_image_)([0-9]+)(\..*)/echo "\1$((\2+1))"/e''')
  if filename_no_extension == ""
    let filename_no_extension = 'pasted_image_0'
  endif
  let filename_no_extension = substitute(filename_no_extension, '\n$', '', '')

  let filename = filename_no_extension . '.' . extension
  let dir_with_filename = outdir . '/' . filename

" FROM HERE ON OUT IT SHOULD BE DONE
  call system(printf('xclip -selection clipboard -t %s -o > %s',
    \ shellescape(mimetype), shellescape(dir_with_filename)))

  let @* = '![[' . filename . ']]'
  normal! "*p
  " if we get this far, we pasted an image -> want to automatically break to a
  " new line.
  execute "normal! o\<Esc>"
  write

endfunction


"Project-specific settings
silent! so .vimlocal
