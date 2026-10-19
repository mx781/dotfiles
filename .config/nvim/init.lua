vim.cmd('source ~/.vimrc')

-- Failsafe for huge files (e.g. minified single-line JSON): give them the
-- 'bigfile' filetype so nothing filetype-driven (LSP, treesitter, copilot)
-- ever attaches, then strip the per-buffer options that are expensive on one
-- enormous line.
local bigfile_bytes = 1024 * 1024 -- 1 MiB
local bigfile_cols = 10000        -- chars in the first line

vim.filetype.add({
  pattern = {
    ['.*'] = {
      priority = math.huge,
      function(path, buf)
        if not path or not vim.api.nvim_buf_is_valid(buf) then return end
        if vim.bo[buf].buftype ~= '' then return end
        local size = vim.fn.getfsize(path)
        if size < 0 then return end
        if size > bigfile_bytes then return 'bigfile' end
        -- Small overall, but can still be one pathological line.
        local first = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
        if first and #first > bigfile_cols then return 'bigfile' end
      end,
    },
  },
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'bigfile',
  callback = function(ev)
    vim.b[ev.buf].bigfile = true
    vim.b[ev.buf].matchparen_timeout = 10
    vim.b[ev.buf].matchparen_insert_timeout = 10
    vim.bo[ev.buf].swapfile = false
    vim.bo[ev.buf].undofile = false
    vim.bo[ev.buf].undolevels = -1
    vim.bo[ev.buf].synmaxcol = 200
    vim.api.nvim_buf_call(ev.buf, function()
      vim.opt_local.foldmethod = 'manual'
      vim.opt_local.foldexpr = ''
      vim.opt_local.number = false
      vim.opt_local.relativenumber = false
      vim.opt_local.cursorline = false
      vim.opt_local.colorcolumn = ''
      vim.opt_local.signcolumn = 'no'
      vim.opt_local.conceallevel = 0
      vim.opt_local.spell = false
      vim.opt_local.list = false
      vim.opt_local.wrap = false
    end)
    -- Syntax is started after FileType, so turn it off on the next tick.
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(ev.buf) then
        vim.bo[ev.buf].syntax = 'off'
      end
    end)
    vim.notify(
      ('bigfile: %s — syntax/LSP/folds disabled'):format(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(ev.buf), ':t')),
      vim.log.levels.WARN
    )
  end,
})

-- Stronger diff backgrounds than Catppuccin's subtle default tints.
require('codediff').setup({
  diff = {
    compact = true,
  },
  highlights = {
    line_insert = '#264b36',
    line_delete = '#59313b',
    char_insert = '#3b6b43',
    char_delete = '#85414c',
  },
})

-- CodeDiff owns compact folds. Its window option writes otherwise trigger
-- Neovim 0.12's global Treesitter refresh, which can retain deleted buffers.
-- Suppress OptionSet only while CodeDiff applies/restores its compact folds.
local compact = require('codediff.ui.view.compact')
if not compact.dotfiles_optionset_workaround then
  for _, name in ipairs({ 'enable', 'disable', 'refresh' }) do
    local original = compact[name]
    compact[name] = function(...)
      local eventignore = vim.o.eventignore
      vim.opt.eventignore:append('OptionSet')
      local ok, result = pcall(original, ...)
      vim.o.eventignore = eventignore
      if not ok then error(result, 0) end
      return result
    end
  end
  compact.dotfiles_optionset_workaround = true
end

-- CodeDiff resets wrap during rendering and window entry; restore it afterward.
local codediff_wrap_pending = false
local function wrap_codediff_panes()
  if codediff_wrap_pending then return end
  codediff_wrap_pending = true
  vim.schedule(function()
    codediff_wrap_pending = false
    local lifecycle = package.loaded['codediff.ui.lifecycle']
    if not lifecycle then return end
    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
      local session = lifecycle.get_session(tab)
      if session then
        for _, win in pairs({ session.original_win, session.modified_win, session.result_win }) do
          if vim.api.nvim_win_is_valid(win) then
            vim.wo[win][0].wrap = true
            vim.wo[win][0].linebreak = true
          end
        end
      end
    end
  end)
end
local codediff_wrap_group = vim.api.nvim_create_augroup('DotfilesCodeDiffWrap', { clear = true })
vim.api.nvim_create_autocmd('User', {
  group = codediff_wrap_group,
  pattern = { 'CodeDiffOpen', 'CodeDiffFileSelect' },
  callback = wrap_codediff_panes,
})
vim.api.nvim_create_autocmd({ 'BufWinEnter', 'WinEnter' }, {
  group = codediff_wrap_group,
  callback = wrap_codediff_panes,
})
vim.api.nvim_create_autocmd('OptionSet', {
  group = codediff_wrap_group,
  pattern = 'wrap',
  callback = function()
    if vim.v.option_new == false or vim.v.option_new == '0' then wrap_codediff_panes() end
  end,
})

local treesitter = require('nvim-treesitter')
treesitter.setup {
  install_dir = vim.fn.stdpath('data') .. '/site',
}
treesitter.install { 'c', 'lua', 'vim', 'vimdoc', 'query', 'python', 'bash' }
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'c', 'lua', 'vim', 'vimdoc', 'query', 'python', 'bash' },
  callback = function() vim.treesitter.start() end,
})

require('mason').setup({})
require('mason-lspconfig').setup({
  ensure_installed = { "pyright"  },
  automatic_enable = {
  }
})

-- Reserve a space in the gutter
vim.opt.signcolumn = 'yes'

-- Add cmp_nvim_lsp capabilities settings to all LSP servers
-- This should be executed before you configure any language server
vim.lsp.config('*', {
  capabilities = require('cmp_nvim_lsp').default_capabilities(),
})

-- This is where you enable features that only work
-- if there is a language server active in the file
vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'LSP actions',
  callback = function(event)
    local opts = {buffer = event.buf}

    vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
    vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
    vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
    vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
    vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
    vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
    vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
    vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
    vim.keymap.set({'n', 'x'}, '<F3>', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
    vim.keymap.set('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
    vim.keymap.set('n', 'gl', '<cmd>lua vim.diagnostic.open_float()<cr>', opts)
  end,
})

vim.lsp.config('pyright', {
  handlers = {
    ['textDocument/rename'] = function(err, result, ctx, config)
      -- Pyright can emit annotation IDs without the corresponding metadata.
      -- https://github.com/microsoft/pyright/issues/10671
      if result then
        local annotations = result.changeAnnotations or {}
        for _, change in ipairs(result.documentChanges or {}) do
          for _, edit in ipairs(change.edits or {}) do
            if edit.annotationId and not annotations[edit.annotationId] then
              edit.annotationId = nil
            end
          end
        end
      end
      return vim.lsp.handlers['textDocument/rename'](err, result, ctx, config)
    end,
  },
})
vim.lsp.config('rust_analyzer', {
  settings = {
    ['rust-analyzer'] = {
      check = {
        -- An explicit command avoids rust-analyzer's flycheck stdout/stderr files.
        overrideCommand = { 'cargo', 'check', '--workspace', '--all-targets', '--message-format=json' },
      },
    },
  },
})
vim.lsp.enable({ 'pyright', 'rust_analyzer' })

local cmp = require('cmp')

cmp.setup({
  sources = {
    {name = 'nvim_lsp'},
  },
  snippet = {
    expand = function(args)
      -- You need Neovim v0.10 to use vim.snippet
      vim.snippet.expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({}),
})

vim.api.nvim_create_user_command('Leetcode', function()
  vim.cmd('vsplit')
  vim.cmd('wincmd l')
  vim.cmd('term')
  vim.api.nvim_chan_send(vim.b.terminal_job_id, 'source venv/bin/activate && while true; do ipython; done\n')
  vim.cmd('wincmd h')
end, {})

require("fzf-lua").setup({})

require('leap').add_default_mappings()
-- leap maps x/X in visual mode to leap-till motions, clobbering the
-- standard "select + x = delete selection" behavior; restore it.
vim.keymap.del('x', 'x')
vim.keymap.del('x', 'X')
require('leap').opts.special_keys.prev_target = '<bs>'
require('leap').opts.special_keys.prev_group = '<bs>'
-- require('leap.user').set_repeat_keys('<cr>', '<bs>')

local obsidian_workspaces = {}
if vim.fn.isdirectory(vim.fn.expand('~/hub/knowledge')) == 1 then
  table.insert(obsidian_workspaces, {
    name = "knowledge",
    path = "~/hub/knowledge",
  })
end

local local_workspaces_path = vim.fn.expand('~/hub/dotfiles/.config/nvim/workspaces.lua.private')
if vim.fn.filereadable(local_workspaces_path) == 1 then
  vim.list_extend(obsidian_workspaces, dofile(local_workspaces_path))
end

if #obsidian_workspaces > 0 then
  require("obsidian").setup({
    workspaces = obsidian_workspaces,
    follow_img_func = function(img)
      vim.fn.jobstart({"xdg-open", img})
    end,
    follow_url_func = function(url)
      vim.fn.jobstart({"xdg-open", url})
    end
  })
end
