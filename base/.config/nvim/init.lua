vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

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
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.scrolloff = 3

vim.opt.wrap = false
vim.opt.colorcolumn = '80'

vim.opt.undofile = true
vim.opt.signcolumn = 'yes'
vim.opt.termguicolors = true
vim.opt.updatetime = 250
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold' }, {
  command = 'checktime',
})

-- Toggle word wrap with <leader>w
vim.keymap.set("n", "<leader>w", function()
  vim.wo.wrap = not vim.wo.wrap
  vim.wo.linebreak = vim.wo.wrap   -- only use linebreak if wrapping
  vim.wo.breakindent = vim.wo.wrap -- same for breakindent
end, { desc = "Toggle word wrap" })

vim.keymap.set("n", "<leader>i", function()
  vim.lsp.buf.format({ async = true })
end, { desc = "Format current buffer" })

-- diagnostics
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = "Show diagnostic" })
vim.keymap.set('n', '<leader>q', function() require('fzf-lua').diagnostics_document() end, { desc = "List diagnostics" })

-- clipboard operations
vim.keymap.set({'n', 'v'}, '<leader>y', '"+y', { desc = "Yank to clipboard" })
vim.keymap.set({'n', 'v'}, '<leader>yy', '"+yy', { desc = "Yank line to clipboard" })
vim.keymap.set({'n', 'v'}, '<leader>p', '"+p', { desc = "Paste from clipboard" })
vim.keymap.set({'n', 'v'}, '<leader>P', '"+P', { desc = "Paste before from clipboard" })

-- plugins
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'

if not vim.uv.fs_stat(lazypath) then ---@diagnostic disable-line: undefined-field
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable',
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

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
      if not pcall(function() vim.cmd('colorscheme rose-pine') end) then
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

  -- keybinding help
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    config = function()
      local wk = require('which-key')
      wk.setup({ preset = 'helix' })
      wk.add({
        { '<leader>h', group = 'git hunks' },
        { '<leader>y', group = 'clipboard' },
      })
    end,
  },

  -- file tree
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    keys = {
      { '<leader>t', '<cmd>NvimTreeToggle<cr>', desc = "Toggle file tree" },
    },
    opts = {
      git = { enable = true },
      renderer = {
        highlight_git = 'name',
      },
    },
  },

  -- fuzzy finder
  {
    'ibhagwan/fzf-lua',
    name = 'fzf',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    keys = {
      { '<leader>f', function() require('fzf-lua').files() end, desc = "Find files" },
      { '<leader>b', function() require('fzf-lua').buffers() end, desc = "Find buffers" },
      { '<leader>/', function() require('fzf-lua').grep_project() end, desc = "Grep project" },
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

          vim.keymap.set('n', ']c', gs.next_hunk, {buffer = bufnr, desc = "Next hunk"})
          vim.keymap.set('n', '[c', gs.prev_hunk, {buffer = bufnr, desc = "Prev hunk"})
          vim.keymap.set('n', '<leader>hs', gs.stage_hunk, {buffer = bufnr, desc = "Stage hunk"})
          vim.keymap.set('n', '<leader>hr', gs.reset_hunk, {buffer = bufnr, desc = "Reset hunk"})
          vim.keymap.set('n', '<leader>hp', gs.preview_hunk, {buffer = bufnr, desc = "Preview hunk"})
          vim.keymap.set('n', '<leader>hb', function() gs.blame_line{full=true} end, {buffer = bufnr, desc = "Blame line"})
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
      ---@diagnostic disable-next-line: missing-fields
      require'nvim-treesitter.configs'.setup {
        ensure_installed = {
          'javascript', 'typescript', 'lua', 'vim', 'vimdoc', 'query',
          'go', 'python', 'html', 'css', 'json', 'yaml', 'bash', 'zig',
        },
        sync_install = false,
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
      }
    end,
  },

  -- neovim lua development
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {},
  },

  -- lsp
  {
    'neovim/nvim-lspconfig',
    event = 'BufReadPre',
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
    },
    config = function()
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
          function(server_name)
            require('lspconfig')[server_name].setup({})
          end,
        }
      })
    end,
  },

  -- autocomplete
  {
    'saghen/blink.cmp',
    version = '1.*',
    event = 'InsertEnter',
    dependencies = {
      'L3MON4D3/LuaSnip',
    },
    opts = {
      keymap = { preset = 'default' },
      sources = {
        default = { 'lsp', 'snippets', 'path', 'buffer' },
      },
      snippets = { preset = 'luasnip' },
    },
  },
})
