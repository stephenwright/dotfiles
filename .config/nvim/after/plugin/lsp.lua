local lsp = require('lsp-zero')

lsp.preset('recommended')
lsp.on_attach(function(client, bufnr)
  -- see :help lsp-zero-keybindings
  -- to learn the available actions
  lsp.default_keymaps({ buffer = bufnr })
end)

lsp.setup_servers({
  'eslint',
  'tsserver',
  'html',
  'cssls',
})

require('lspconfig').lua_ls.setup({
  settings = {
    Lua = {
      diagnostics = {
        globals = { 'vim' },
      },
    },
  },
})

require('cmp').setup({
  sources = {
    { name = 'copilot' },
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  },
})

require('mason').setup({})
require('mason-lspconfig').setup({
  -- Replace the language servers listed here
  -- with the ones you want to install
  ensure_installed = {'tsserver', 'eslint', 'html', 'cssls'},
  handlers = {
    lsp.default_setup,
  }
})

