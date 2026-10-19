# worktree-context.nvim

A small Neovim plugin for navigating an existing repository's Git worktrees.
Requires Neovim 0.10+ and Git. fzf-lua and NERDTree are optional integrations.
It does not create/delete worktrees, switch Git branches, or source project code.

## Install and disable

With vim-plug, add this plugin's absolute path:

```vim
Plug expand('~/hub/dotfiles/plugins/worktree-context.nvim')
```

It initializes automatically. Remove/comment that line and restart to disable it,
or run `:WorktreeDisable` for the current session. To prevent initialization while
keeping it installed, set `vim.g.worktree_context_enabled = false` before plugins
load. No core mappings or project files depend on its presence.

Options may be set before loading via `vim.g.worktree_context_options`, or later:

```lua
require('worktree-context').setup({
  nerdtree = true,
  statusline = true,
  remember = true, -- restore the last selected worktree per repository
  mappings = {
    pick = '<leader>ww',
    toggle = '<leader><Tab>',
    grep_all = '<leader>wg',
  }, -- false disables all mappings; individual entries may also be false
})
```

## Workflow

Start Neovim in the main checkout (or any linked checkout). `:WorktreeSwitch`
opens an fzf-lua picker, falling back to `vim.ui.select`. It discovers worktrees
through `git worktree list --porcelain -z`, including ones created externally.
Bare repositories and missing directories are excluded. Paths containing spaces
are supported. `:WorktreeSwitch /absolute/path` switches directly.

`<leader>ww` picks a worktree. `<leader><Tab>` / `:WorktreePrevious` returns to the
previous worktree. Switching changes global cwd and the current NERDTree root,
preserving focus, windows, buffers, unsaved edits, and the current file. A closed
NERDTree remains closed and refreshes when entered. Existing explicit window/tab
local cwd overrides elsewhere are not removed; avoid mixing `:lcd` / `:tcd` with
this global workflow. Automatic cwd-following plugins/options can likewise
override the chosen context.

Normal cwd-based file and grep pickers now search the selected worktree. Buffers
remain global, including the normal buffer picker. Visiting a buffer in another
worktree never switches context. The statusline displays the active cwd's
worktree directory and branch (or detached commit), which may differ from the
visible file's worktree. It refreshes on directory changes and focus gain.

The selected worktree is remembered across Neovim restarts, independently for
each repository. Starting in any checkout of a repository, or entering it with
global `:cd` from another repository, restores its last selected worktree. Moving
between worktrees of the same repository updates that selection. This changes
the navigation cwd, not the files or buffers you opened explicitly. Removed
worktrees and invalid state files fall back to the checkout you entered.
State is stored under `stdpath('state')/worktree-context/`, keyed by Git's shared
repository directory, with one atomically replaced JSON file per repository.
Set `remember = false` to disable persistence; `state_dir` overrides its location.
Selections are saved when the context changes, so closing an older editor does
not overwrite a newer editor's selection.

`<leader>wg` / `:WorktreeGrepAll` uses fzf-lua to search exactly the available
worktree directories, respecting its normal ignore rules. Result paths
distinguish copies of the same file. Opening a result does not change cwd.
Worktrees nested inside another checkout should be ignored there, so ordinary
recursive file searches do not descend into those nested checkouts.

Project `.vimlocal` settings remain those loaded at startup. Existing terminal
processes, environments, LSP clients and local mappings are not reconfigured.
After switching, the `User WorktreeContextChanged` event supplies
`args.data.path` and `args.data.previous` for optional integrations.

## File-specific operations (such as sync)

Never derive a current file's remote destination from the navigation cwd. Use:

```lua
local context, err = require('worktree-context').file_context()
-- context = { root = '/repo/worktree', path = '/repo/worktree/src/a.py',
--             relative = 'src/a.py' }
-- Returns nil, error for an unnamed buffer or a file outside Git.
local relative = require('worktree-context').relative_path() -- raises on error
```

These helpers resolve the file's own Git root, even while another worktree is
active. They run Git with argument arrays, not shell interpolation. The rl-bot
project mapping independently uses the same Git-root rule so syncing continues
to work when the plugin is disabled.

## Tests

From the dotfiles directory:

```sh
nvim --headless -u NONE -l plugins/worktree-context.nvim/tests/run.lua
nvim --headless -u NONE -l plugins/worktree-context.nvim/tests/persistence.lua
```

Tests use temporary local repositories and never run sync or access a remote.

`tests/integration.lua` additionally checks the locally installed NERDTree and
fzf-lua integrations and rl-bot's `.vimlocal`. It invokes sync only after replacing
rsync with a temporary argument-capture stub; it never contacts a remote host.
