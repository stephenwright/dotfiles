local lsp_zero = require('lsp-zero')

lsp_zero.on_attach(function(client, bufnr)
  -- see :help lsp-zero-keybindings
  -- to learn the available actions
  lsp_zero.default_keymaps({ buffer = bufnr })
end)

require('mason').setup({})
require('mason-lspconfig').setup({
  ensure_installed = {
    'ts_ls',
    'eslint',
    'html',
    'cssls',
    'lua_ls',
    'gopls',
    'pyright',
    'zls',
  },
  handlers = {
    lsp_zero.default_setup,
    lua_ls = function()
      require('lspconfig').lua_ls.setup({
        settings = {
          Lua = {
            diagnostics = {
              globals = { 'vim' },
            },
          },
        },
      })
    end,
  }
})

local cmp = require('cmp')

cmp.setup({
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  },
})

