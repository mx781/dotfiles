-- Run with: nvim --headless -u NONE -l plugins/worktree-context.nvim/tests/recovery.lua
vim.opt.rtp:prepend(vim.fn.getcwd() .. '/plugins/worktree-context.nvim')
local plugin = require('worktree-context')
local tmp = vim.fn.tempname() .. ' deleted worktrees'
local main, linked = tmp .. '/main', tmp .. '/linked tree'
local function run(args)
  local result = vim.system(args, { text = true }):wait()
  assert(result.code == 0, result.stderr)
end
local function git(...)
  run(vim.list_extend({ 'git', '-C', main }, { ... }))
end
local ok, err = xpcall(function()
  run({ 'git', 'init', '-q', '-b', 'main', main })
  vim.fn.writefile({ 'original' }, main .. '/file.txt')
  git('add', '.')
  git('-c', 'user.name=Test', '-c', 'user.email=test@example.invalid', 'commit', '-qm', 'initial')
  vim.cmd.cd(vim.fn.fnameescape(main))
  vim.cmd.edit(vim.fn.fnameescape(main .. '/file.txt'))
  local buffer = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { 'unsaved edit' })
  for _, remember in ipairs({ true, false }) do
    plugin.setup({ remember = remember, nerdtree = false, state_dir = tmp .. '/state' })
    for _, trigger in ipairs({ 'picker', 'command', 'focus', 'buffer', 'switch' }) do
      git('worktree', 'add', '--detach', linked, 'HEAD')
      assert(plugin.switch(linked))
      -- Delete and prune externally, leaving Neovim inside an unlinked cwd.
      git('worktree', 'remove', linked)
      git('worktree', 'prune')
      if trigger == 'picker' then
        local opened = false
        package.loaded['fzf-lua'] = { fzf_exec = function(entries, opts)
          assert(vim.fn.getcwd() == main, 'Picker started with deleted cwd')
          assert(#entries == 1, 'Picker retained deleted worktree')
          opts.actions.default({ entries[1] })
          opened = true
        end }
        plugin.pick()
        assert(opened, 'Worktree picker did not open')
      elseif trigger == 'switch' then
        assert(plugin.switch(main), 'Direct switching from deleted cwd failed')
      else
        local event = ({ command = 'CmdlineEnter', focus = 'FocusGained', buffer = 'BufEnter' })[trigger]
        vim.api.nvim_exec_autocmds(event, { modeline = false })
      end
      assert(vim.fn.getcwd() == main, 'Did not recover on ' .. trigger)
      assert(vim.api.nvim_get_current_buf() == buffer and vim.bo[buffer].modified,
        'Recovery changed or saved the current buffer')
      assert(plugin.statusline():find('main:main', 1, true), 'Statusline did not recover')
    end
    -- Returning to a surviving non-Git directory must clear the recovery repo.
    vim.cmd.cd(vim.fn.fnameescape(tmp))
    plugin.ensure_cwd()
    assert(vim.fn.getcwd() == tmp, 'Recovery overrode a valid cwd')
    plugin.disable()
    vim.cmd.cd(vim.fn.fnameescape(main))
  end
  print('PASS: deleted/pruned active worktree, picker, command, focus, buffer, direct switch, persistence opt-out, dirty buffers')
end, debug.traceback)
plugin.disable()
vim.cmd.cd('/tmp')
vim.fn.delete(tmp, 'rf')
if not ok then io.stderr:write(err .. '\n'); vim.cmd('cquit 1') end
vim.cmd('qa!')
