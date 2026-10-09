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

local plugged = vim.fn.stdpath('data') .. '/plugged'
for _, plugin in ipairs(vim.fn.readdir(plugged)) do
  vim.opt.runtimepath:append(plugged .. '/' .. plugin)
end

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

vim.lsp.config('pyright', {})
vim.lsp.config('rust_analyzer', {})
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
  vim.cmd('Copilot disable')
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

if vim.fn.isdirectory(vim.fn.expand('~/hub/knowledge')) == 1 then
  require("obsidian").setup({
    workspaces = {
      { name = "knowledge", path = "~/hub/knowledge" },
      { name = "work", path = "~/hub/maxtor/vault" },
    },
    follow_img_func = function(img)
      vim.fn.jobstart({"xdg-open", img})
    end,
    follow_url_func = function(url)
      vim.fn.jobstart({"xdg-open", url})
    end
  })
end
