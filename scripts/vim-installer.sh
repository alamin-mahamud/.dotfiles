#!/bin/bash

# Standalone Vim Installer and Configuration Script
# DRY orchestrator for enhanced vim setup with plugins and DevOps configurations
# This creates a practical vim setup with helpful documentation for beginners
# Usage: curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/vim-installer.sh | bash

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
LOG_FILE="/tmp/vim-install-$(date +%Y%m%d_%H%M%S).log"
BACKUP_DIR="$HOME/.vim-backup-$(date +%Y%m%d_%H%M%S)"

# Logging
exec > >(tee -a "$LOG_FILE") 2>&1

# Print colored output
print_status() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ✓ $1"
}

print_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ✗ $1"
}

print_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ⚠ $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root!"
        print_status "Please run as a regular user with sudo privileges."
        exit 1
    fi
}

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        print_success "Detected macOS"
    elif [[ -f /etc/os-release ]]; then
        source /etc/os-release
        OS=$ID
        print_success "Detected $PRETTY_NAME"
    else
        print_error "Unsupported operating system"
        exit 1
    fi
}

# Backup existing vim configuration (idempotent)
backup_existing_configs() {
    local files_to_backup=(
        "$HOME/.vimrc"
        "$HOME/.vim"
    )
    
    local backup_needed=false
    for file in "${files_to_backup[@]}"; do
        if [[ -e "$file" ]] && [[ ! -L "$file" ]]; then
            backup_needed=true
            break
        fi
    done
    
    if [[ "$backup_needed" == true ]]; then
        print_status "Backing up existing vim configuration..."
        mkdir -p "$BACKUP_DIR"
        
        for file in "${files_to_backup[@]}"; do
            if [[ -e "$file" ]] && [[ ! -L "$file" ]]; then
                cp -r "$file" "$BACKUP_DIR/" 2>/dev/null || true
                print_status "Backed up $(basename "$file")"
            fi
        done
        print_success "Backups saved to $BACKUP_DIR"
    fi
}

# Install vim (idempotent)
install_vim() {
    print_status "Checking vim installation..."
    
    if command -v vim &> /dev/null; then
        print_success "Vim is already installed ($(vim --version | head -n1))"
        return 0
    fi
    
    print_status "Installing vim..."
    case "$OS" in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get install -y vim
            ;;
        fedora|centos|rhel|rocky|almalinux)
            sudo dnf install -y vim || sudo yum install -y vim
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm vim
            ;;
        alpine)
            sudo apk add --no-cache vim
            ;;
        opensuse*|sles)
            sudo zypper install -y vim
            ;;
        macos)
            if ! command -v brew &> /dev/null; then
                print_warning "Homebrew not found. Installing Homebrew first..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install vim
            ;;
        *)
            print_error "Unsupported OS for vim installation: $OS"
            return 1
            ;;
    esac
    
    print_success "Vim installed successfully"
}

# Create vim directories (idempotent)
create_vim_directories() {
    print_status "Creating vim directories..."
    
    local vim_dirs=(
        "$HOME/.vim/autoload"
        "$HOME/.vim/backup"
        "$HOME/.vim/colors"
        "$HOME/.vim/swap"
        "$HOME/.vim/undo"
        "$HOME/.vim/plugged"
    )
    
    for dir in "${vim_dirs[@]}"; do
        mkdir -p "$dir"
    done
    
    print_success "Vim directories created"
}

# Install vim-plug (idempotent)
install_vim_plug() {
    print_status "Installing vim-plug plugin manager..."
    
    local plug_file="$HOME/.vim/autoload/plug.vim"
    
    if [[ -f "$plug_file" ]]; then
        print_success "vim-plug is already installed"
        # Update vim-plug
        print_status "Updating vim-plug..."
        curl -fsSLo "$plug_file" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        return 0
    fi
    
    curl -fsSLo "$plug_file" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    
    print_success "vim-plug installed"
}

# Create vimrc configuration (idempotent)
create_vimrc() {
    print_status "Creating vim configuration..."
    
    cat > "$HOME/.vimrc" << 'VIMRC_EOF'
" ============================================================================
" VIM CONFIGURATION FOR DEVOPS ENGINEERS
" A practical setup with helpful comments for vim beginners
" Generated by vim-installer.sh
" ============================================================================

" ============================================================================
" VIM BASICS - UNDERSTANDING MODES
" ============================================================================
" Vim has several modes:
" 1. NORMAL mode (default) - For navigation and commands (press Esc)
" 2. INSERT mode - For typing text (press i, a, o, or O)
" 3. VISUAL mode - For selecting text (press v, V, or Ctrl+v)
" 4. COMMAND mode - For running commands (press :)

" ============================================================================
" GENERAL SETTINGS
" ============================================================================

set nocompatible              " Disable vi compatibility
filetype plugin indent on     " Enable file type detection
syntax enable                 " Enable syntax highlighting
set encoding=utf-8            " Set encoding to UTF-8
set number                    " Show line numbers
set relativenumber            " Show relative line numbers
set ruler                     " Show cursor position
set showcmd                   " Show command being typed
set showmatch                 " Highlight matching brackets
set mouse=a                   " Enable mouse support
set cursorline                " Highlight current line
set colorcolumn=80            " Show column marker at 80 characters
set scrolloff=5               " Keep 5 lines visible above/below cursor
set lazyredraw                " Redraw only when needed
set laststatus=2              " Always show status line
set wildmenu                  " Enhanced command line completion
set wildignore=*.o,*~,*.pyc,*.class,*.git,*.svn

" ============================================================================
" SEARCH SETTINGS
" ============================================================================

set incsearch                 " Incremental search
set hlsearch                  " Highlight search results
set ignorecase                " Case-insensitive search
set smartcase                 " Case-sensitive if uppercase used

" ============================================================================
" INDENTATION SETTINGS
" ============================================================================

set tabstop=2                 " Visual spaces per TAB
set softtabstop=2             " Spaces in TAB when editing
set shiftwidth=2              " Spaces for autoindent
set expandtab                 " Convert TABs to spaces
set autoindent                " Copy indent from current line
set smartindent               " Smart autoindenting

" ============================================================================
" BACKUP AND UNDO SETTINGS
" ============================================================================

set backup                    " Keep backup files
set backupdir=~/.vim/backup// " Backup directory
set undofile                  " Persistent undo
set undodir=~/.vim/undo//     " Undo directory
set directory=~/.vim/swap//   " Swap file directory

" ============================================================================
" KEY MAPPINGS
" ============================================================================

let mapleader = ","           " Set leader key to comma

" Quick save and quit
nnoremap <leader>w :w<CR>
nnoremap <leader>q :wq<CR>
nnoremap <leader>Q :q!<CR>

" Clear search highlight
nnoremap <leader><space> :nohlsearch<CR>

" Window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Visual mode indenting
vnoremap < <gv
vnoremap > >gv

" Move visual blocks
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

" Double tap j to escape insert mode
inoremap jj <Esc>

" Format JSON (requires jq)
nnoremap <leader>j :%!jq '.'<CR>

" Format XML (requires xmllint)
nnoremap <leader>x :%!xmllint --format -<CR>

" Remove trailing whitespace
nnoremap <leader>t :%s/\s\+$//e<CR>

" Convert tabs to spaces
nnoremap <leader>T :%s/\t/  /g<CR>

" ============================================================================
" FILE TYPE SETTINGS
" ============================================================================

" YAML files
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab

" Python files
autocmd FileType python setlocal ts=4 sts=4 sw=4 expandtab

" Shell scripts
autocmd FileType sh setlocal ts=4 sts=4 sw=4 expandtab

" JSON files
autocmd FileType json setlocal conceallevel=0

" Markdown files
autocmd FileType markdown setlocal wrap linebreak

" ============================================================================
" CLIPBOARD INTEGRATION
" ============================================================================

if has('clipboard')
    set clipboard=unnamed,unnamedplus
endif

" Copy to clipboard in visual mode
vnoremap <C-c> "+y

" Paste from clipboard
inoremap <C-v> <Esc>"+pa

" ============================================================================
" COLOR SCHEME
" ============================================================================

colorscheme desert
highlight LineNr ctermfg=grey
highlight CursorLineNr ctermfg=yellow
highlight Search cterm=NONE ctermfg=black ctermbg=yellow

" ============================================================================
" STATUS LINE
" ============================================================================

set statusline=
set statusline+=%F                          " Full file path
set statusline+=%m                          " Modified flag
set statusline+=%r                          " Readonly flag
set statusline+=%h                          " Help file flag
set statusline+=%=                          " Left/right separator
set statusline+=%y                          " File type
set statusline+=\ [%{&fileencoding?&fileencoding:&encoding}]
set statusline+=\ [line\ %l/%L]             " Current/total lines
set statusline+=\ [col\ %c]                 " Column number

" ============================================================================
" PLUGINS (using vim-plug)
" ============================================================================

call plug#begin('~/.vim/plugged')

" File explorer
Plug 'preservim/nerdtree'

" Status line
Plug 'vim-airline/vim-airline'

" Git integration
Plug 'airblade/vim-gitgutter'

" Fuzzy file finder
Plug 'ctrlpvim/ctrlp.vim'

" Multiple cursors
Plug 'terryma/vim-multiple-cursors'

" Auto-close brackets
Plug 'jiangmiao/auto-pairs'

" Comment lines
Plug 'tpope/vim-commentary'

" Better syntax highlighting
Plug 'sheerun/vim-polyglot'

" Surround text objects
Plug 'tpope/vim-surround'

" Git wrapper
Plug 'tpope/vim-fugitive'

call plug#end()

" ============================================================================
" PLUGIN CONFIGURATIONS
" ============================================================================

" NERDTree
nnoremap <leader>n :NERDTreeToggle<CR>
let NERDTreeShowHidden=1
let NERDTreeIgnore=['\.pyc$', '\~$', '\.swp$', '\.git$']

" CtrlP
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'
let g:ctrlp_show_hidden = 1
let g:ctrlp_working_path_mode = 'ra'

" GitGutter
set updatetime=100
let g:gitgutter_max_signs = 500

" Airline
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'unique_tail'

" ============================================================================
" QUICK REFERENCE
" ============================================================================
" NAVIGATION:
"   h/j/k/l     - left/down/up/right
"   w/b         - next/previous word
"   0/$         - beginning/end of line
"   gg/G        - beginning/end of file
"   Ctrl+f/b    - page down/up
"
" EDITING:
"   i/a         - insert before/after cursor
"   o/O         - new line below/above
"   dd          - delete line
"   yy          - copy line
"   p/P         - paste after/before
"   u/Ctrl+r    - undo/redo
"
" CUSTOM SHORTCUTS:
"   ,w          - quick save
"   ,q          - save and quit
"   ,n          - toggle file tree
"   ,j          - format JSON
"   ,t          - remove trailing spaces
"   jj          - escape insert mode
"   Ctrl+p      - fuzzy file search
" ============================================================================
VIMRC_EOF
    
    print_success "Vim configuration created"
}

# Create practice file
create_practice_file() {
    print_status "Creating practice file..."
    
    cat > "$HOME/vim-practice.txt" << 'PRACTICE_EOF'
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
[paste the copied line below with p]

Practice search:
Find the word "practice" with /practice

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
- Use :w to save changes
- Use :q to quit (or :q! without saving)
PRACTICE_EOF
    
    print_success "Practice file created at ~/vim-practice.txt"
}

# Create cheatsheet
create_cheatsheet() {
    print_status "Creating vim cheatsheet..."
    
    cat > "$HOME/vim-cheatsheet.txt" << 'CHEATSHEET_EOF'
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
   Press n for next match, N for previous

3. Find and replace:
   :%s/old_text/new_text/g     (all occurrences)
   :s/old_text/new_text/g      (current line)

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

CUSTOM SHORTCUTS (THIS CONFIG):
,w - quick save
,q - save and quit
,n - toggle file tree (NERDTree)
,j - format JSON
,t - remove trailing spaces
jj - escape insert mode
Ctrl+p - fuzzy file search

PLUGIN COMMANDS:
NERDTree (File Explorer):
  ,n - toggle file tree
  o - open file/folder
  s - open in split
  t - open in new tab

CtrlP (Fuzzy Finder):
  Ctrl+p - open fuzzy finder
  Ctrl+j/k - navigate results
  Enter - open file

Commentary:
  gcc - comment/uncomment line
  gc (visual) - comment selection

GitGutter:
  [c - previous change
  ]c - next change
  ,hs - stage hunk
  ,hu - undo hunk

PRO TIPS:
- Number before command repeats it (5dd deletes 5 lines)
- . (dot) repeats last command
- u undoes last change, Ctrl+r redoes
- :set paste before pasting from clipboard
- :set nopaste after pasting
CHEATSHEET_EOF
    
    print_success "Cheatsheet created at ~/vim-cheatsheet.txt"
}

# Install plugins
install_plugins() {
    print_status "Installing vim plugins..."
    
    # Check if vim supports plugin installation
    if ! vim --version | grep -q "+eval"; then
        print_warning "Your vim version doesn't support plugins"
        return 1
    fi
    
    # Install plugins silently
    vim +PlugInstall +qall 2>/dev/null || {
        print_warning "Plugin installation may require manual completion"
        print_status "Run ':PlugInstall' inside vim to install plugins"
    }
    
    print_success "Plugin installation initiated"
}

# Show summary
show_summary() {
    echo
    echo "========================================"
    echo "Vim Installation Summary"
    echo "========================================"
    echo
    print_success "✓ Vim installed and configured"
    print_success "✓ vim-plug plugin manager installed"
    print_success "✓ Enhanced vimrc with DevOps settings"
    print_success "✓ Practice file created"
    print_success "✓ Cheatsheet created"
    print_success "✓ Plugins ready to install"
    echo
    print_status "📋 Files created:"
    echo "  • ~/.vimrc - Main configuration"
    echo "  • ~/vim-practice.txt - Practice file"
    echo "  • ~/vim-cheatsheet.txt - Quick reference"
    echo
    print_status "📁 Log file: $LOG_FILE"
    if [[ -d "$BACKUP_DIR" ]]; then
        print_status "📁 Backups: $BACKUP_DIR"
    fi
    echo
    print_warning "📝 Next Steps:"
    echo "  1. Practice with: vim ~/vim-practice.txt"
    echo "  2. View cheatsheet: cat ~/vim-cheatsheet.txt"
    echo "  3. Install plugins: Open vim and run :PlugInstall"
    echo
    print_status "🔑 Essential Commands:"
    echo "  • i = insert mode (start typing)"
    echo "  • Esc = back to normal mode"
    echo "  • :w = save file"
    echo "  • :q = quit vim"
    echo "  • :wq = save and quit"
    echo "  • u = undo last change"
    echo
    print_status "💡 Custom Shortcuts:"
    echo "  • ,w = quick save"
    echo "  • ,n = toggle file tree"
    echo "  • ,j = format JSON"
    echo "  • jj = escape insert mode"
    echo "  • Ctrl+p = fuzzy file search"
    echo
    print_status "🚀 Your vim environment is ready for DevOps work!"
}

# Main installation
main() {
    clear
    echo "========================================"
    echo "Standalone Vim Installer & Configuration"
    echo "========================================"
    echo
    
    # Pre-flight checks
    check_root
    detect_os
    
    # Backup existing configuration
    backup_existing_configs
    
    # Installation steps
    install_vim
    create_vim_directories
    install_vim_plug
    create_vimrc
    create_practice_file
    create_cheatsheet
    install_plugins
    
    # Show summary
    show_summary
}

# Run main function if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi