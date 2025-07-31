#!/usr/bin/env bash

# Standalone Vim Installer and Configuration Script
# Perfect for DevOps engineers working on remote servers
# This creates a practical vim setup with helpful comments for beginners
# Usage: curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/refs/heads/master/standalone-vim-installer.sh | bash
#   or: ./vim-installer.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Standalone Vim Installer & Configuration${NC}"
echo -e "${BLUE}============================================${NC}"

# Create vim configuration directory
mkdir -p ~/.vim/{autoload,backup,colors,undo}

# Install vim if not present
if ! command -v vim &> /dev/null; then
    echo -e "${YELLOW}📦 Installing vim...${NC}"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install vim
    elif command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y vim
    elif command -v yum &> /dev/null; then
        sudo yum install -y vim
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y vim
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm vim
    elif command -v apk &> /dev/null; then
        sudo apk add --no-cache vim
    else
        echo -e "${RED}❌ Could not install vim automatically. Please install manually.${NC}"
        exit 1
    fi
fi

# Backup existing vimrc if it exists
if [[ -f ~/.vimrc ]]; then
    mv ~/.vimrc ~/.vimrc.backup.$(date +%Y%m%d_%H%M%S)
    echo -e "${YELLOW}📁 Backed up existing .vimrc${NC}"
fi

# Create the vimrc configuration
cat > ~/.vimrc << 'VIMRC'
" ============================================================================
" VIM CONFIGURATION FOR DEVOPS ENGINEERS
" A practical setup with extensive comments for vim beginners
" ============================================================================

" ============================================================================
" VIM BASICS - UNDERSTANDING MODES
" ============================================================================
" Vim has several modes:
" 1. NORMAL mode (default) - For navigation and commands
"    - Press 'Esc' to enter this mode from any other mode
" 2. INSERT mode - For typing/editing text
"    - Press 'i' to insert before cursor
"    - Press 'a' to insert after cursor
"    - Press 'o' to insert new line below
"    - Press 'O' to insert new line above
" 3. VISUAL mode - For selecting text
"    - Press 'v' for character selection
"    - Press 'V' for line selection
"    - Press 'Ctrl+v' for block selection
" 4. COMMAND mode - For running commands
"    - Press ':' to enter command mode
"    - Common commands: :w (save), :q (quit), :wq (save & quit)

" ============================================================================
" GENERAL SETTINGS
" ============================================================================

" Disable compatibility with vi which can cause unexpected issues
set nocompatible

" Enable file type detection and load plugins for specific file types
filetype plugin indent on

" Enable syntax highlighting (colors for code)
syntax enable

" Show line numbers on the left
set number

" Show relative line numbers (helps with jumping: 5j moves 5 lines down)
set relativenumber

" Always show cursor position in bottom right
set ruler

" Show command in bottom bar as you type it
set showcmd

" Highlight matching brackets/parentheses when cursor is on them
set showmatch

" Enable mouse support (click to position cursor, scroll, select)
set mouse=a

" Set encoding to UTF-8 (important for special characters)
set encoding=utf-8

" ============================================================================
" SEARCH SETTINGS
" ============================================================================

" Search as you type (incremental search)
set incsearch

" Highlight all search matches
set hlsearch

" Ignore case when searching...
set ignorecase

" ...unless search pattern contains uppercase letters
set smartcase

" Clear search highlight with ,<space> (comma then space)
nnoremap <leader><space> :nohlsearch<CR>

" ============================================================================
" INDENTATION SETTINGS (CRUCIAL FOR YAML/PYTHON)
" ============================================================================

" Number of visual spaces per TAB character
set tabstop=2

" Number of spaces in TAB when editing
set softtabstop=2

" Number of spaces to use for autoindent
set shiftwidth=2

" Convert TABs to spaces (important for YAML)
set expandtab

" Copy indent from current line when starting new line
set autoindent

" Smart autoindenting when starting new line
set smartindent

" ============================================================================
" UI CONFIGURATION
" ============================================================================

" Show a visual line at column 80 (helps keep lines short)
set colorcolumn=80

" Highlight current line (makes it easier to see where you are)
set cursorline

" Always show at least 5 lines above/below cursor
set scrolloff=5

" Redraw only when needed (faster macros)
set lazyredraw

" Show status line always
set laststatus=2

" Enhanced command line completion (TAB to see options)
set wildmenu

" Ignore these files when using wildmenu
set wildignore=*.o,*~,*.pyc,*.class,*.git,*.svn

" ============================================================================
" BACKUP AND UNDO SETTINGS
" ============================================================================

" Keep backup files in central directory (not next to files)
set backup
set backupdir=~/.vim/backup//

" Keep undo history in files (can undo even after closing)
set undofile
set undodir=~/.vim/undo//

" Keep swap files in central directory
set directory=~/.vim/swap//

" Create directories if they don't exist
if !isdirectory(expand("~/.vim/backup"))
    call mkdir(expand("~/.vim/backup"), "p")
endif
if !isdirectory(expand("~/.vim/undo"))
    call mkdir(expand("~/.vim/undo"), "p")
endif
if !isdirectory(expand("~/.vim/swap"))
    call mkdir(expand("~/.vim/swap"), "p")
endif

" ============================================================================
" KEY MAPPINGS (CUSTOM SHORTCUTS)
" ============================================================================
" Note: <leader> is set to comma (,) by default

" Set leader key to comma (easier to reach than backslash)
let mapleader = ","

" Quick save with ,w
nnoremap <leader>w :w<CR>

" Quick save and quit with ,q
nnoremap <leader>q :wq<CR>

" Move between windows with Ctrl+h/j/k/l (like tmux)
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Easier moving of code blocks in visual mode
" < and > to indent/dedent, then gv to reselect
vnoremap < <gv
vnoremap > >gv

" Move visual selection up/down with J/K
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

" Double tap j to escape insert mode (easier than reaching for Esc)
inoremap jj <Esc>

" ============================================================================
" FILE TYPE SPECIFIC SETTINGS
" ============================================================================

" YAML files - critical for DevOps
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab

" Python files
autocmd FileType python setlocal ts=4 sts=4 sw=4 expandtab

" Shell scripts
autocmd FileType sh setlocal ts=4 sts=4 sw=4 expandtab

" JSON files - show quotes
autocmd FileType json setlocal conceallevel=0

" Markdown files - enable word wrap
autocmd FileType markdown setlocal wrap linebreak

" ============================================================================
" USEFUL COMMANDS FOR DEVOPS
" ============================================================================

" Format JSON with ,j (requires jq)
nnoremap <leader>j :%!jq '.'<CR>

" Format XML with ,x (requires xmllint)
nnoremap <leader>x :%!xmllint --format -<CR>

" Remove trailing whitespace with ,t
nnoremap <leader>t :%s/\s\+$//e<CR>

" Convert tabs to spaces in whole file with ,T
nnoremap <leader>T :%s/\t/  /g<CR>

" ============================================================================
" CLIPBOARD INTEGRATION
" ============================================================================

" Use system clipboard for copy/paste (requires vim compiled with +clipboard)
" Check with: vim --version | grep clipboard
if has('clipboard')
    set clipboard=unnamed,unnamedplus
endif

" Copy to clipboard in visual mode with Ctrl+c
vnoremap <C-c> "+y

" Paste from clipboard with Ctrl+v
inoremap <C-v> <Esc>"+pa

" ============================================================================
" COLOR SCHEME
" ============================================================================

" Use desert colorscheme (works well on most terminals)
colorscheme desert

" Override some colors for better visibility
highlight LineNr ctermfg=grey
highlight CursorLineNr ctermfg=yellow
highlight Search cterm=NONE ctermfg=black ctermbg=yellow

" ============================================================================
" STATUS LINE CONFIGURATION
" ============================================================================

" Custom status line showing useful information
set statusline=
set statusline+=%F                          " Full file path
set statusline+=%m                          " Modified flag
set statusline+=%r                          " Readonly flag
set statusline+=%h                          " Help file flag
set statusline+=%=                          " Left/right separator
set statusline+=%y                          " File type
set statusline+=\ [%{&fileencoding?&fileencoding:&encoding}]  " Encoding
set statusline+=\ [line\ %l/%L]             " Current line / total lines
set statusline+=\ [col\ %c]                 " Column number

" ============================================================================
" QUICK REFERENCE (ESSENTIAL COMMANDS)
" ============================================================================
" NAVIGATION:
"   h/j/k/l     - left/down/up/right
"   w/b         - next/previous word
"   0/$         - beginning/end of line
"   gg/G        - beginning/end of file
"   Ctrl+f/b    - page down/up
"   :123        - go to line 123
"
" EDITING:
"   i/a         - insert before/after cursor
"   o/O         - new line below/above
"   x           - delete character
"   dd          - delete line
"   yy          - copy line
"   p/P         - paste after/before cursor
"   u/Ctrl+r    - undo/redo
"   .           - repeat last command
"
" VISUAL MODE:
"   v           - character selection
"   V           - line selection
"   Ctrl+v      - block selection
"   d           - delete selection
"   y           - copy selection
"   >/<         - indent/dedent
"
" SEARCH & REPLACE:
"   /pattern    - search forward
"   ?pattern    - search backward
"   n/N         - next/previous match
"   :%s/old/new/g - replace all in file
"   :s/old/new/g  - replace all in line
"
" FILES:
"   :w          - save
"   :q          - quit
"   :wq or :x   - save and quit
"   :q!         - quit without saving
"   :e file     - open file
"   :split      - horizontal split
"   :vsplit     - vertical split
"
" CUSTOM SHORTCUTS (defined above):
"   ,w          - quick save
"   ,q          - save and quit
"   ,<space>    - clear search highlight
"   ,j          - format JSON
"   ,t          - remove trailing whitespace
"   jj          - escape insert mode
"
" ============================================================================
" Remember: If you make a mistake, press 'u' to undo!
" Press 'Esc' if you get stuck in any mode
" ============================================================================
VIMRC

# Create a simple vim cheat sheet
cat > ~/vim-cheatsheet.txt << 'CHEATSHEET'
VIM QUICK REFERENCE FOR DEVOPS
==============================

EMERGENCY EXITS:
- Stuck? Press Esc, then type :q! to quit without saving
- Want to save and quit? Press Esc, then type :wq

MODES:
- Press 'Esc' → NORMAL mode (for commands)
- Press 'i' → INSERT mode (for typing)
- Press 'v' → VISUAL mode (for selecting)
- Press ':' → COMMAND mode (for vim commands)

ESSENTIAL COMMANDS:
Movement:           Editing:            File Operations:
h - left           i - insert text     :w - save file
j - down           x - delete char     :q - quit vim
k - up             dd - delete line    :wq - save & quit
l - right          yy - copy line      :q! - quit no save
                   p - paste

PRACTICAL EXAMPLES FOR DEVOPS:

1. Edit a config file:
   vim /etc/nginx/nginx.conf

2. Search for a word:
   Press / then type the word, press Enter
   Press n for next match

3. Find and replace:
   :%s/old_text/new_text/g

4. Delete multiple lines:
   Press V, select lines with j/k, press d

5. Copy and paste:
   Position cursor on line, press yy to copy
   Move to destination, press p to paste

6. Format JSON file:
   Open file: vim data.json
   Format it: press ,j (comma then j)

7. Jump to specific line:
   :42 (goes to line 42)

8. Compare files side by side:
   vim -d file1.conf file2.conf

CUSTOM SHORTCUTS IN THIS CONFIG:
,w - quick save
,q - save and quit
,j - format JSON
,t - remove trailing spaces
jj - escape insert mode (instead of Esc key)

PRO TIPS:
- Number before command repeats it (5dd deletes 5 lines)
- . (dot) repeats last command
- u undoes last change
- Ctrl+r redoes
CHEATSHEET

# Install vim-plug (lightweight plugin manager)
echo -e "${YELLOW}🔌 Installing vim-plug...${NC}"
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Add plugin section to vimrc
cat >> ~/.vimrc << 'PLUGINS'

" ============================================================================
" PLUGINS (using vim-plug)
" ============================================================================
" To install plugins: Open vim and run :PlugInstall

call plug#begin('~/.vim/plugged')

" File tree explorer - press ,n to toggle
Plug 'preservim/nerdtree'

" Better status line
Plug 'vim-airline/vim-airline'

" Git integration - shows git changes in files
Plug 'airblade/vim-gitgutter'

" Fuzzy file finder - press Ctrl+p to search files
Plug 'ctrlpvim/ctrlp.vim'

" Multiple cursors - Ctrl+n to select next occurrence
Plug 'terryma/vim-multiple-cursors'

" Auto-close brackets and quotes
Plug 'jiangmiao/auto-pairs'

" Comment lines with gc in visual mode
Plug 'tpope/vim-commentary'

" Better syntax highlighting for many languages
Plug 'sheerun/vim-polyglot'

call plug#end()

" Plugin configurations
" NERDTree - File explorer
nnoremap <leader>n :NERDTreeToggle<CR>
let NERDTreeShowHidden=1  " Show hidden files

" CtrlP - Fuzzy finder
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_show_hidden = 1

" GitGutter - Update time
set updatetime=100

" ============================================================================
" After adding these plugins, restart vim and run :PlugInstall
" ============================================================================
PLUGINS

# Create a simple test file to practice with
cat > ~/vim-practice.txt << 'PRACTICE'
VIM PRACTICE FILE
=================

Practice basic movements:
- Use hjkl to move around
- Try pressing w to jump words forward
- Try pressing b to jump words backward

Practice editing (press i to start):
TODO: Add your name here: ___________
TODO: Add today's date: ___________

Practice visual selection:
Select this line with V and delete with d
Select this line with V and copy with y
[paste the copied line below this one with p]

Practice search:
Find the word "practice" in this file with /practice

YAML practice (check indentation):
services:
  nginx:
    image: nginx:latest
    ports:
      - "80:80"
  redis:
    image: redis:alpine
    ports:
      - "6379:6379"

JSON practice (try ,j to format):
{"name":"test","version":"1.0","dependencies":{"express":"^4.17.1","mongoose":"^5.12.0"},"scripts":{"start":"node index.js","test":"jest"}}

Practice find and replace:
Change all 'old_version' to 'new_version':
old_version: 1.0.0
app_old_version: 1.0.0
db_old_version: 1.0.0

Lines with trailing spaces (try ,t to clean):
This line has trailing spaces
So does this one

Remember:
- Press Esc if you get stuck
- Use :w to save your changes
- Use :q to quit (or :q! to quit without saving)
PRACTICE

echo ""
echo -e "${GREEN}✅ Vim installation and configuration complete!${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e "${YELLOW}📚 Quick Start Guide:${NC}"
echo -e "  1. Practice with: ${GREEN}vim ~/vim-practice.txt${NC}"
echo -e "  2. View cheatsheet: ${GREEN}cat ~/vim-cheatsheet.txt${NC}"
echo -e "  3. Install plugins: Open vim and run ${GREEN}:PlugInstall${NC}"
echo ""
echo -e "${YELLOW}🔑 Essential Commands to Remember:${NC}"
echo -e "  - ${GREEN}i${NC} = insert mode (start typing)"
echo -e "  - ${GREEN}Esc${NC} = back to normal mode"
echo -e "  - ${GREEN}:w${NC} = save file"
echo -e "  - ${GREEN}:q${NC} = quit vim"
echo -e "  - ${GREEN}:wq${NC} = save and quit"
echo -e "  - ${GREEN}u${NC} = undo last change"
echo ""
echo -e "${YELLOW}💡 Custom Shortcuts:${NC}"
echo -e "  - ${GREEN},w${NC} = quick save"
echo -e "  - ${GREEN},n${NC} = toggle file tree"
echo -e "  - ${GREEN},j${NC} = format JSON"
echo -e "  - ${GREEN}jj${NC} = escape insert mode"
echo ""
echo -e "${BLUE}Start practicing with: vim ~/vim-practice.txt${NC}"
