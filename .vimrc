" Minimal VIM Configuration - DevOps Focused

" Basic settings
set nocompatible
set encoding=utf-8
set number relativenumber
set cursorline
set showmatch
set hidden
set nobackup nowritebackup noswapfile
set autoread
set history=1000
set scrolloff=8
set sidescrolloff=8
set signcolumn=yes
set updatetime=300

" Indentation
set expandtab
set tabstop=2
set shiftwidth=2
set softtabstop=2
set autoindent
set smartindent

" Search
set ignorecase
set smartcase
set incsearch
set hlsearch

" Interface
set wildmenu
set wildmode=longest:full,full
set showcmd
set laststatus=2
set ruler
set wrap linebreak

" Performance
set lazyredraw
set ttyfast

" Split behavior
set splitbelow
set splitright

" Leader key
let mapleader=" "

" Key mappings
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>x :x<CR>
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
nnoremap <leader>v :vsplit<CR>
nnoremap <leader>s :split<CR>
nnoremap <leader><space> :nohlsearch<CR>

" Buffer navigation
nnoremap <leader>b :ls<CR>:b<space>
nnoremap <leader>n :bnext<CR>
nnoremap <leader>p :bprevious<CR>
nnoremap <leader>d :bdelete<CR>

" Quick edit vimrc
nnoremap <leader>ev :vsplit $MYVIMRC<CR>
nnoremap <leader>sv :source $MYVIMRC<CR>

" YAML/Ansible
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab

" Terraform
autocmd FileType terraform setlocal ts=2 sts=2 sw=2 expandtab

" Python
autocmd FileType python setlocal ts=4 sts=4 sw=4 expandtab

" Shell
autocmd FileType sh setlocal ts=2 sts=2 sw=2 expandtab

" JSON
autocmd FileType json setlocal ts=2 sts=2 sw=2 expandtab

" Markdown
autocmd FileType markdown setlocal wrap linebreak

" Status line
set statusline=%F%m%r%h%w\ [%{&ff}]\ [%Y]\ [%l,%v][%p%%]

" Colors
syntax enable
set background=dark
if has('termguicolors')
  set termguicolors
endif

" Persistent undo
if has('persistent_undo')
  set undodir=~/.vim/undodir
  set undofile
endif

" Mouse support
if has('mouse')
  set mouse=a
endif

" Clipboard
if has('clipboard')
  set clipboard=unnamed,unnamedplus
endif