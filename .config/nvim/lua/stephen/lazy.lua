-- lazy
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  { 'nvim-tree/nvim-web-devicons' },
  -- themes
  { 'catppuccin/nvim', name = 'catppuccin' },
  { 'rose-pine/neovim', name = 'rose-pine' },
  -- statusline
  { 'nvim-lualine/lualine.nvim', name = 'lualine' },
  -- fuzzy finder
  { 'ibhagwan/fzf-lua', name = 'fzf' },
  -- git
  { 'tpope/vim-fugitive', name = 'fugitive' },
  { 'kdheepak/lazygit.nvim', name = 'lazygit' },
  { 'lewis6991/gitsigns.nvim', name = 'gitsigns' },
  -- code analysis
  { 'nvim-treesitter/nvim-treesitter', name = 'treesitter', build = ':TSUpdate'},
  { 'github/copilot.vim', name = 'copilot' },
  {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v3.x',
    dependencies = {
      -- lsp
      'neovim/nvim-lspconfig',
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
      -- autocomplete
      'hrsh7th/nvim-cmp',
      'hrsh7th/cmp-nvim-lsp',
      -- snippets
      'L3MON4D3/LuaSnip',
    },
  },
})

