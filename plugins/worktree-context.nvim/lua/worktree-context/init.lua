local M = {}
local config, previous, indicator = {}, nil, ''
local owned_maps, commands = {}, {}
local group
local default_statusline
local active_repo, restoring

local function git(path, args)
  local argv = { 'git', '-C', path }
  vim.list_extend(argv, args)
  local result = vim.system(argv, { text = true }):wait()
  if result.code ~= 0 then
    return nil, vim.trim(result.stderr or 'Git failed')
  end
  return result.stdout
end

local function canonical(path)
  return vim.uv.fs_realpath(path) or vim.fs.normalize(vim.fn.fnamemodify(path, ':p'))
end

function M.root(path)
  path = path or vim.fn.getcwd()
  if vim.fn.isdirectory(path) == 0 then path = vim.fs.dirname(path) end
  local output, err = git(path, { 'rev-parse', '--show-toplevel' })
  if not output then return nil, err end
  return canonical(vim.trim(output))
end

-- Resolve from the file, never from the active navigation context.
function M.file_context(path)
  path = path or vim.api.nvim_buf_get_name(0)
  if path == '' then return nil, 'Current buffer has no file' end
  path = canonical(path)
  local root, err = M.root(path)
  if not root then return nil, err end
  local prefix = root .. '/'
  if path:sub(1, #prefix) ~= prefix then return nil, 'File is outside its worktree' end
  return { root = root, path = path, relative = path:sub(#prefix + 1) }
end

function M.relative_path(path)
  local context, err = M.file_context(path)
  if not context then error(err) end
  return context.relative
end

function M.list(path)
  local output, err = git(path or vim.fn.getcwd(), { 'worktree', 'list', '--porcelain', '-z' })
  if not output then return nil, err end
  local trees, entry = {}, nil
  for field in (output .. '\0'):gmatch('(.-)%z') do
    if field:sub(1, 9) == 'worktree ' then
      entry = { path = field:sub(10) }
      trees[#trees + 1] = entry
    elseif entry then
      local key, value = field:match('^(%S+)%s*(.*)$')
      if key then entry[key] = value ~= '' and value or true end
    end
  end
  return vim.tbl_filter(function(tree)
    return not tree.bare and vim.fn.isdirectory(tree.path) == 1
  end, trees)
end

local function notify(message)
  vim.notify(message, vim.log.levels.WARN, { title = 'Worktree context' })
end

local function repository_id(root)
  local path = git(root, { 'rev-parse', '--path-format=absolute', '--git-common-dir' })
  return path and canonical(vim.trim(path))
end

local function state_path(repo)
  return config.state_dir .. '/' .. vim.fn.sha256(repo) .. '.json'
end

local function remembered_worktree(repo)
  local ok, state = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(state_path(repo)), '\n'))
  end)
  if ok and type(state) == 'table' and state.repository == repo and type(state.path) == 'string' then
    return state.path
  end
end

local function remember_worktree(repo, root)
  local path = state_path(repo)
  local temporary = path .. '.' .. vim.fn.getpid() .. '.tmp'
  local ok, err = pcall(function()
    vim.fn.mkdir(config.state_dir, 'p', 448)
    assert(vim.fn.writefile({ vim.json.encode({ repository = repo, path = root }) }, temporary) == 0)
    vim.fn.setfperm(temporary, 'rw-------')
    assert(vim.uv.fs_rename(temporary, path))
  end)
  if not ok then
    vim.fn.delete(temporary)
    notify('Could not remember worktree: ' .. tostring(err))
  end
end

local function refresh()
  local root = M.root()
  if not root then indicator = ''; return end
  local branch = git(root, { 'symbolic-ref', '--quiet', '--short', 'HEAD' })
  if not branch then branch = git(root, { 'rev-parse', '--short', 'HEAD' }) end
  indicator = vim.fs.basename(root) .. ':' .. vim.trim(branch or '?')
  vim.cmd.redrawstatus()
end

function M.statusline()
  return indicator ~= '' and (' [wt ' .. indicator:gsub('%%', '%%%%') .. ']') or ''
end

local function reroot_tree()
  if not config.nerdtree or vim.fn.exists(':NERDTreeCWD') ~= 2 then return end
  -- Do not open a closed sidebar. Its root is refreshed on its next BufEnter.
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'nerdtree' then
      local current = vim.api.nvim_get_current_win()
      local ok, err = pcall(vim.cmd, 'NERDTreeCWD')
      if vim.api.nvim_win_is_valid(current) then vim.api.nvim_set_current_win(current) end
      if not ok then notify(err) end
      return
    end
  end
end

function M.switch(path)
  local trees, err = M.list()
  if not trees then notify(err); return false end
  path = canonical(path)
  local found = false
  for _, tree in ipairs(trees) do
    if canonical(tree.path) == path then found = true; break end
  end
  if not found then notify('Not an available worktree of this repository: ' .. path); return false end
  local old = M.root() or vim.fn.getcwd()
  if canonical(vim.fn.getcwd()) == path then return true end
  -- :cd clears the current window/tab local directory and sets the global cwd.
  -- Other windows' explicit :lcd overrides are left alone.
  vim.cmd.cd(vim.fn.fnameescape(path))
  previous = old
  reroot_tree()
  refresh()
  vim.api.nvim_exec_autocmds('User', {
    pattern = 'WorktreeContextChanged', modeline = false,
    data = { path = path, previous = old },
  })
  return true
end

function M.toggle()
  if not previous then notify('No previous worktree yet'); return false end
  return M.switch(previous)
end

function M.pick()
  local trees, err = M.list()
  if not trees then notify(err); return end
  local root = M.root()
  local function label(tree)
    local branch = tree.branch and tree.branch:gsub('^refs/heads/', '') or ('detached ' .. (tree.HEAD or ''):sub(1, 8))
    return (canonical(tree.path) == root and '* ' or '  ') .. branch .. '  ' .. tree.path
  end
  local ok, fzf = pcall(require, 'fzf-lua')
  if not ok then
    vim.ui.select(trees, { prompt = 'Worktrees', format_item = label }, function(tree)
      if tree then M.switch(tree.path) end
    end)
    return
  end
  local entries, paths = {}, {}
  for i, tree in ipairs(trees) do
    local text = i .. ' ' .. label(tree):gsub('[\r\n\t]', ' ')
    entries[#entries + 1], paths[tostring(i)] = text, tree.path
  end
  fzf.fzf_exec(entries, {
    prompt = 'Worktrees> ',
    actions = { ['default'] = function(selected)
      if selected[1] then M.switch(paths[selected[1]:match('^(%d+)')]) end
    end },
  })
end

function M.grep_all()
  local trees, err = M.list()
  if not trees then notify(err); return end
  local ok, fzf = pcall(require, 'fzf-lua')
  if not ok then notify('Searching all worktrees requires fzf-lua'); return end
  local paths = vim.tbl_map(function(tree) return tree.path end, trees)
  -- Explicit worktree paths distinguish identical filenames in different trees.
  fzf.live_grep({ search_paths = paths, prompt = 'All worktrees> ' })
end

function M.disable()
  if group then vim.api.nvim_del_augroup_by_id(group); group = nil end
  for _, name in ipairs(commands) do pcall(vim.api.nvim_del_user_command, name) end
  for _, mapping in ipairs(owned_maps) do
    local current = vim.fn.maparg(mapping.lhs, 'n', false, true)
    if current.desc == mapping.desc then
      vim.keymap.del('n', mapping.lhs)
      if next(mapping.old) then vim.fn.mapset('n', false, mapping.old) end
    end
  end
  local suffix = "%{v:lua.require'worktree-context'.statusline()}"
  vim.o.statusline = vim.o.statusline:gsub(vim.pesc(suffix), '')
  if default_statusline and vim.o.statusline == default_statusline then vim.o.statusline = '' end
  default_statusline = nil
  commands, owned_maps, indicator, previous = {}, {}, '', nil
  active_repo, restoring = nil, false
end

local function enter_repository()
  if restoring or not config.remember then return end
  local root = M.root()
  local repo = root and repository_id(root)
  if not repo then active_repo, previous = nil, nil; return end
  if repo ~= active_repo then
    active_repo, previous = repo, nil
    local saved = remembered_worktree(repo)
    if saved and canonical(saved) ~= root then
      -- Revalidate against Git: removed worktrees and paths in another repo
      -- must never redirect the editor, even if the state file is stale.
      for _, tree in ipairs(M.list(root) or {}) do
        if canonical(tree.path) == canonical(saved) then
          restoring = true
          local ok, err = pcall(M.switch, tree.path)
          restoring = false
          if not ok then notify(err) end
          root = M.root() or root
          break
        end
      end
    end
  end
  remember_worktree(repo, root)
end

function M.setup(opts)
  M.disable()
  config = vim.tbl_deep_extend('force', {
    nerdtree = true, statusline = true,
    remember = true,
    state_dir = vim.fn.stdpath('state') .. '/worktree-context',
    mappings = { pick = '<leader>ww', toggle = '<leader><Tab>', grep_all = '<leader>wg' },
  }, opts or {})
  local function command(name, callback, options)
    vim.api.nvim_create_user_command(name, callback, options or {})
    commands[#commands + 1] = name
  end
  command('WorktreeSwitch', function(args)
    if args.args == '' then M.pick() else M.switch(args.args) end
  end, { nargs = '?', complete = 'dir' })
  command('WorktreePrevious', M.toggle)
  command('WorktreeGrepAll', M.grep_all)
  command('WorktreeDisable', M.disable)
  for action, lhs in pairs(config.mappings or {}) do
    if lhs and lhs ~= '' then
      local desc = 'Worktree context: ' .. action
      owned_maps[#owned_maps + 1] = { lhs = lhs, old = vim.fn.maparg(lhs, 'n', false, true), desc = desc }
      vim.keymap.set('n', lhs, M[action], { desc = desc })
    end
  end
  group = vim.api.nvim_create_augroup('WorktreeContext', { clear = true })
  vim.api.nvim_create_autocmd('DirChanged', { group = group, callback = function(event)
    if event.match == 'global' then enter_repository() end
    refresh()
  end })
  vim.api.nvim_create_autocmd('FocusGained', { group = group, callback = refresh })
  local tree_busy = false
  vim.api.nvim_create_autocmd('BufEnter', { group = group, callback = function()
    if vim.bo.filetype == 'nerdtree' and not tree_busy then
      tree_busy = true
      reroot_tree()
      tree_busy = false
    end
  end })
  if config.statusline then
    if vim.o.statusline == '' then
      default_statusline = '%<%f %h%m%r%=%-14.(%l,%c%V%) %P'
      vim.o.statusline = default_statusline
    end
    vim.o.statusline = vim.o.statusline .. "%{v:lua.require'worktree-context'.statusline()}"
  end
  enter_repository()
  refresh()
end

return M
