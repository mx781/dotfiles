-- Local-only repositories and state, including a separate Neovim process.
local plugin_path = vim.fn.getcwd() .. '/plugins/worktree-context.nvim'
vim.opt.rtp:prepend(plugin_path)
local plugin = require('worktree-context')
local tmp = vim.fn.tempname() .. ' sticky worktrees'
local main, linked = tmp .. '/main', tmp .. '/linked tree'
local other, other_linked = tmp .. '/other', tmp .. '/other linked'
local state_dir = tmp .. '/state'
local options = { nerdtree = false, statusline = false, mappings = false, state_dir = state_dir }
local function run(args)
  local result = vim.system(args, { text = true, env = { NVIM_LOG_FILE = tmp .. '/nvim.log' } }):wait()
  assert(result.code == 0, result.stderr .. result.stdout)
end
local function create_repo(root, tree)
  run({ 'git', 'init', '-q', '-b', 'main', root })
  vim.fn.writefile({ 'original' }, root .. '/file.txt')
  run({ 'git', '-C', root, 'add', '.' })
  run({ 'git', '-C', root, '-c', 'user.name=Test', '-c', 'user.email=test@example.invalid', 'commit', '-qm', 'initial' })
  run({ 'git', '-C', root, 'worktree', 'add', '-qb', 'feature', tree })
end
local function cd(path)
  vim.cmd.cd(vim.fn.fnameescape(path))
end
local ok, err = xpcall(function()
  vim.fn.mkdir(tmp, 'p')
  create_repo(main, linked)
  create_repo(other, other_linked)
  cd(main)
  vim.cmd.edit(vim.fn.fnameescape(main .. '/file.txt'))
  local buffer = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { 'unsaved' })
  plugin.setup(options)
  assert(plugin.switch(linked))
  local files = vim.fn.glob(state_dir .. '/*.json', false, true)
  assert(#files == 1)
  local first_state = files[1]
  assert(vim.json.decode(table.concat(vim.fn.readfile(first_state))).path == linked)

  -- A separate editor must restore the selection, including paths with spaces.
  local child = tmp .. '/reopen.lua'
  vim.fn.writefile({
    'vim.opt.rtp:prepend(' .. string.format('%q', plugin_path) .. ')',
    'vim.cmd.cd(' .. string.format('%q', main) .. ')',
    'require("worktree-context").setup(vim.json.decode(' .. string.format('%q', vim.json.encode(options)) .. '))',
    'assert(vim.fn.getcwd() == ' .. string.format('%q', linked) .. ')',
    'vim.cmd("qa!")',
  }, child)
  run({ vim.v.progpath, '--headless', '-u', 'NONE', '-i', 'NONE', '-l', child })

  cd(other)
  assert(vim.fn.getcwd() == other, 'New repo inherited another selection')
  assert(plugin.switch(other_linked))
  cd(main)
  assert(vim.fn.getcwd() == linked, 'Returning to repo did not restore it')
  cd(other)
  assert(vim.fn.getcwd() == other_linked, 'Repo selections were mixed')
  assert(vim.api.nvim_get_current_buf() == buffer and vim.bo[buffer].modified,
    'Restoration changed or saved the current buffer')
  assert(plugin.file_context().root == main, 'File root followed restored cwd')
  assert(#vim.fn.glob(state_dir .. '/*.json', false, true) == 2)

  -- Explicit same-repo navigation becomes the new remembered context.
  cd(other)
  cd(main)
  cd(other_linked)
  assert(vim.fn.getcwd() == other)

  -- Reassigning the remembered path to an unrelated repo must not redirect.
  plugin.disable()
  run({ 'git', '-C', main, 'worktree', 'remove', linked })
  run({ 'git', 'init', '-q', linked })
  cd(main)
  plugin.setup(options)
  assert(vim.fn.getcwd() == main, 'Restored an unregistered worktree')
  plugin.disable()
  vim.fn.writefile({ 'not JSON' }, first_state)
  plugin.setup(options)
  assert(vim.fn.getcwd() == main, 'Invalid state broke setup')

  -- Disabling persistence neither restores nor writes state.
  assert(plugin.switch(other) == false, 'Accepted another repository')
  plugin.disable()
  local before = table.concat(vim.fn.readfile(first_state), '\n')
  local disabled = vim.tbl_extend('force', options, { remember = false })
  plugin.setup(disabled)
  cd(other_linked)
  assert(vim.fn.getcwd() == other_linked)
  assert(table.concat(vim.fn.readfile(first_state), '\n') == before)
  plugin.disable()
  print('PASS: restart persistence, per-repo isolation, explicit cd, dirty buffers, stale/corrupt state, opt-out')
end, debug.traceback)
plugin.disable()
cd('/tmp')
vim.fn.delete(tmp, 'rf')
if not ok then io.stderr:write(err .. '\n'); vim.cmd('cquit 1') end
vim.cmd('qa!')
