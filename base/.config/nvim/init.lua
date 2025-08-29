---@diagnostic disable: undefined-global

-- leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- options
vim.opt.number = true

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.incsearch = true

vim.opt.scrolloff = 3

vim.opt.wrap = false
vim.opt.colorcolumn = '80'

-- Toggle word wrap with <leader>w
vim.keymap.set("n", "<leader>w", function()
  vim.wo.wrap = not vim.wo.wrap
  vim.wo.linebreak = vim.wo.wrap   -- only use linebreak if wrapping
  vim.wo.breakindent = vim.wo.wrap -- same for breakindent
end, { desc = "Toggle word wrap" })

-- clipboard operations
vim.keymap.set({'n', 'v'}, '<leader>y', '"+y')
vim.keymap.set({'n', 'v'}, '<leader>yy', '"+yy')
vim.keymap.set({'n', 'v'}, '<leader>p', '"+p')
vim.keymap.set({'n', 'v'}, '<leader>P', '"+P')

-- plugins
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

-- plugins
require('lazy').setup({

  -- themes
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
  },

  {
    'rose-pine/neovim',
    name = 'rose-pine',
    priority = 1000,
    config = function()
      require('rose-pine').setup({
        disable_italics = true,
      })
      -- Try rose-pine first, fallback to catppuccin
      local ok, _ = pcall(vim.cmd, 'colorscheme rose-pine')
      if not ok then
        vim.cmd('colorscheme catppuccin')
      end
    end,
  },

  -- statusline
  {
    'nvim-lualine/lualine.nvim',
    name = 'lualine',
    event = 'VeryLazy',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('lualine').setup({
        options = {
          theme = 'rose-pine',
          component_separators = { left = '', right = ''},
          section_separators = { left = '', right = ''},
        },
        sections = {
          lualine_a = {'mode'},
          lualine_b = {'branch', 'diff', 'diagnostics'},
          lualine_c = {'filename'},
          lualine_x = {'encoding', 'fileformat', 'filetype'},
          lualine_y = {'progress'},
          lualine_z = {'location'}
        },
      })
    end,
  },

  -- fuzzy finder
  {
    'ibhagwan/fzf-lua',
    name = 'fzf',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    keys = {
      { '<leader>f', function() require('fzf-lua').files() end, mode = 'n', silent = true },
      { '<leader>b', function() require('fzf-lua').buffers() end, mode = 'n', silent = true },
      { '<leader>/', function() require('fzf-lua').grep_project() end, mode = 'n', silent = true },
    },
  },

  -- git
  {
    'kdheepak/lazygit.nvim',
    name = 'lazygit',
    cmd = 'LazyGit',
    keys = {
      { '<leader>g', '<cmd>LazyGit<cr>', desc = 'LazyGit' },
    },
  },

  {
    'lewis6991/gitsigns.nvim',
    name = 'gitsigns',
    event = 'BufReadPre',
    config = function()
      require('gitsigns').setup({
        signs = {
          add = { text = '+' },
          change = { text = '~' },
          delete = { text = '_' },
        },
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns

          vim.keymap.set('n', ']c', gs.next_hunk, {buffer = bufnr})
          vim.keymap.set('n', '[c', gs.prev_hunk, {buffer = bufnr})
          vim.keymap.set('n', '<leader>hs', gs.stage_hunk, {buffer = bufnr})
          vim.keymap.set('n', '<leader>hr', gs.reset_hunk, {buffer = bufnr})
          vim.keymap.set('n', '<leader>hp', gs.preview_hunk, {buffer = bufnr})
          vim.keymap.set('n', '<leader>hb', function() gs.blame_line{full=true} end, {buffer = bufnr})
        end
      })
    end,
  },

  -- code analysis
  {
    'nvim-treesitter/nvim-treesitter',
    name = 'treesitter',
    build = ':TSUpdate',
    event = 'BufReadPre',
    config = function()
      require'nvim-treesitter.configs'.setup {
        ensure_installed = { 'javascript', 'typescript', 'lua', 'vim', 'vimdoc', 'query' },
        sync_install = false,
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
      }
    end,
  },

  {
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v3.x',
    event = 'BufReadPre',
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
    config = function()
      local lsp_zero = require('lsp-zero')

      lsp_zero.on_attach(function(client, bufnr)
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
            local lspconfig = require('lspconfig')
            local lua_opts = lsp_zero.nvim_lua_ls()
            lua_opts.settings.Lua.diagnostics.globals = { 'vim' }
            lspconfig.lua_ls.setup(lua_opts)
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
    end,
  },
})

