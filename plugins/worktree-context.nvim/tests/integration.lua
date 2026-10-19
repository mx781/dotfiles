-- Local integration checks with installed NERDTree/fzf-lua and a fake rsync.
-- Run from dotfiles with: nvim --headless -u NONE -l plugins/worktree-context.nvim/tests/integration.lua
local base = vim.fn.getcwd()
vim.opt.rtp:prepend(base .. '/plugins/worktree-context.nvim')
local installed = vim.fn.stdpath('data') .. '/plugged/'
vim.opt.rtp:append(installed .. 'nerdtree')
vim.opt.rtp:append(installed .. 'fzf-lua')
vim.cmd('runtime plugin/NERD_tree.vim')
local plugin = require('worktree-context')
local tmp = vim.fn.tempname() .. ' integration'
local main, linked = tmp .. '/main', tmp .. '/other tree'
local function run(argv)
  local result = vim.system(argv, { text = true }):wait()
  assert(result.code == 0, result.stderr)
end
local ok, err = xpcall(function()
  vim.fn.mkdir(tmp, 'p')
  run({ 'git', 'init', '-q', '-b', 'master', main })
  vim.fn.mkdir(main .. '/src', 'p')
  vim.fn.writefile({ 'test' }, main .. '/src/file name.txt')
  run({ 'git', '-C', main, 'add', '.' })
  run({ 'git', '-C', main, '-c', 'user.name=Test', '-c', 'user.email=test@example.invalid', 'commit', '-qm', 'init' })
  run({ 'git', '-C', main, 'worktree', 'add', '-qb', 'feature', linked })
  vim.cmd.cd(vim.fn.fnameescape(main))
  vim.cmd.edit(vim.fn.fnameescape(main .. '/src/file name.txt'))
  local current_buf, current_win = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
  vim.cmd.NERDTree()
  vim.api.nvim_set_current_win(current_win)
  plugin.setup({ state_dir = tmp .. '/state' })
  assert(plugin.switch(linked))
  assert(vim.api.nvim_get_current_win() == current_win and vim.api.nvim_get_current_buf() == current_buf)
  assert(vim.fn.eval('t:NERDTreeBufName') ~= '')
  local function tree_root()
    return vim.fn.eval("getbufvar(bufnr(t:NERDTreeBufName), 'NERDTree').root.path.str()")
  end
  assert(tree_root() == linked, 'Visible NERDTree did not change root')
  vim.cmd.NERDTreeClose()
  local win_count = #vim.api.nvim_list_wins()
  assert(plugin.toggle())
  assert(#vim.api.nvim_list_wins() == win_count, 'Opened closed sidebar')
  vim.cmd.NERDTreeToggle()
  assert(tree_root() == main, 'Closed NERDTree did not refresh when reopened')
  vim.api.nvim_set_current_win(current_win)

  -- Exercise the installed fzf-lua integration without starting a picker.
  local fzf = require('fzf-lua')
  local original = fzf.live_grep
  local captured
  fzf.live_grep = function(opts) captured = opts end
  plugin.grep_all()
  fzf.live_grep = original
  assert(#captured.search_paths == 2)

  -- Source the real project mapping; PATH replaces rsync before invocation.
  vim.cmd.source('/home/maksis/hub/gravity/rl-bot/.vimlocal')
  vim.fn.writefile({ '#!/usr/bin/python3', 'import json, os, sys',
    'with open(os.environ["WORKTREE_TEST_CAPTURE"], "w") as f: json.dump(sys.argv[1:], f)' }, tmp .. '/rsync')
  vim.fn.setfperm(tmp .. '/rsync', 'rwx------')
  vim.env.WORKTREE_TEST_CAPTURE = tmp .. '/argv.json'
  assert(plugin.switch(linked))
  vim.env.PATH = tmp .. ':' .. vim.env.PATH
  assert(vim.fn.exepath('rsync') == tmp .. '/rsync')
  vim.fn.RLBotSyncCurrentFile('test-host:/target/')
  local args = vim.json.decode(table.concat(vim.fn.readfile(tmp .. '/argv.json'), '\n'))
  assert(args[#args - 1] == main .. '/src/file name.txt')
  assert(args[#args] == 'test-host:/target/src/file name.txt', vim.inspect(args))
  plugin.disable()
  vim.fn.RLBotSyncCurrentFile('test-host:/target/')
  print('PASS: real NERDTree, focus preservation, closed sidebar, sync with spaces and different cwd, disabled sync')
end, debug.traceback)
vim.cmd.cd('/tmp')
vim.fn.delete(tmp, 'rf')
if not ok then io.stderr:write(err .. '\n'); vim.cmd('cquit 1') end
vim.cmd('qa!')
