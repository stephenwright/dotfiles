
" Capture Mouse Wheel
set mouse=a

" Syntax Highlighting
syntax on

" Tabs
set tabstop=2
set expandtab
set shiftwidth=2
set autoindent

" Line numbering
set number

" Don't run in VI mode
set nocompatible

" Show cursor position
set ruler

" Filetype settings
autocmd Filetype ruby setlocal ts=2 sts=2 sw=2 expandtab

" Colour Theme
set t_Co=256
colorscheme Tomorrow-Night

" Shortcuts for dealing with tabs
map <C-j> :tabprevious<CR>
map <C-k> :tabnext<CR>
map <C-S-tab> :tabprevious<CR>
map <C-tab>   :tabnext<CR>
map <C-t>     :tabnew<CR>
map <C-w>     :q<CR>

" Load pathogen.vim plugin
call pathogen#infect()
filetype plugin indent on

