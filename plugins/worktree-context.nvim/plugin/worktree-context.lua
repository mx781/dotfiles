if vim.g.loaded_worktree_context or vim.g.worktree_context_enabled == false then
  return
end
vim.g.loaded_worktree_context = true
require('worktree-context').setup(vim.g.worktree_context_options or {})
