vim.cmd([[
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc
]])

require'nvim-treesitter.configs'.setup {
  ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "python", "bash" },
  sync_install = false,
  auto_install = true,
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = false,
  },
}

require('mason').setup({})
require('mason-lspconfig').setup({
  ensure_installed = { "pyright"  },
  automatic_enable = {
  }
})

-- Reserve a space in the gutter
vim.opt.signcolumn = 'yes'

-- Add cmp_nvim_lsp capabilities settings to lspconfig
-- This should be executed before you configure any language server
local lspconfig_defaults = require('lspconfig').util.default_config
lspconfig_defaults.capabilities = vim.tbl_deep_extend(
  'force',
  lspconfig_defaults.capabilities,
  require('cmp_nvim_lsp').default_capabilities()
)

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

require('lspconfig').pyright.setup({})
require('lspconfig').rust_analyzer.setup({})

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

require('leap').create_default_mappings()
require('leap').opts.special_keys.prev_target = '<bs>'
require('leap').opts.special_keys.prev_group = '<bs>'
-- require('leap.user').set_repeat_keys('<cr>', '<bs>')

require("obsidian").setup({
  workspaces = {
    {
      name = "knowledge",
      path = "~/hub/knowledge",
    },
    {
      name = "work",
      path = "~/hub/maxtor/vault",
    },
  },
  follow_img_func = function(img)
    vim.fn.jobstart({"xdg-open", url})  -- linux
  end
})


require('avante').setup({
    provider = "openai",
    openai = {
        model = "o4-mini", 
        timeout = 180000, -- Timeout in milliseconds, increase this for reasoning models
        -- temperature = 0,
        -- max_completion_tokens = 8192, -- Increase this to include reasoning tokens (for reasoning models)
        --reasoning_effort = "medium", -- low|medium|high, only used for reasoning models
    },
    windows = {
        ask = {
            floating = true,
            border = "rounded",
            start_insert = true,
        },
    }
})
