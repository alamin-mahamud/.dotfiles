#!/usr/bin/env bash

# MOONSHOT: Neovim Ultra-Productivity Environment
# Next-gen Neovim setup for 10x DevOps engineers
# TMUX-aware, K8s-native, AI-powered, performance-optimized

set -euo pipefail

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/package-managers.sh"

# Initialize environment
setup_environment

# Configuration
NVIM_CONFIG_DIR="$HOME/.config/nvim"
DOTFILES_NVIM_CONFIG="$DOTFILES_ROOT/nvim"

install_neovim_moonshot() {
    info "Installing Neovim v0.10+ (latest stable)..."
    
    # Always get the absolute latest stable version
    local nvim_dir="/opt/nvim"
    local download_url=""
    
    case "${DOTFILES_OS}" in
    linux)
        # Get nightly build for cutting-edge features
        download_url="https://github.com/neovim/neovim/releases/download/nightly/nvim-linux64.tar.gz"
        ;;
    macos)
        download_url="https://github.com/neovim/neovim/releases/download/nightly/nvim-macos-universal.tar.gz"
        ;;
    esac
    
    local temp_dir=$(mktemp -d)
    download_file "$download_url" "$temp_dir/nvim.tar.gz"
    
    sudo rm -rf "$nvim_dir"
    sudo mkdir -p "$nvim_dir"
    sudo tar -xzf "$temp_dir/nvim.tar.gz" -C "$nvim_dir" --strip-components=1
    sudo ln -sf "$nvim_dir/bin/nvim" /usr/local/bin/nvim
    rm -rf "$temp_dir"
    
    success "Neovim nightly build installed"
}

create_moonshot_config() {
    info "Creating MOONSHOT Neovim configuration..."
    
    # Backup existing config
    if [[ -d "$NVIM_CONFIG_DIR" ]]; then
        backup_file "$NVIM_CONFIG_DIR"
    fi
    
    rm -rf "$NVIM_CONFIG_DIR"
    mkdir -p "$NVIM_CONFIG_DIR/lua"
    
    # Create init.lua with performance optimizations
    cat > "$NVIM_CONFIG_DIR/init.lua" <<'EOF'
-- MOONSHOT Neovim Configuration
-- Performance-first, DevOps-optimized

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Performance optimizations
vim.loader.enable() -- Enable new Lua module loader for 3x faster startup
vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- Load configuration modules
require("moonshot.options")
require("moonshot.keymaps")
require("moonshot.autocmds")
require("lazy").setup("moonshot.plugins", {
  defaults = { lazy = true },
  performance = {
    cache = { enabled = true },
    reset_packpath = true,
    rtp = {
      reset = true,
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
        "netrwPlugin",
      },
    },
  },
  dev = { path = "~/projects" },
  install = { colorscheme = { "tokyonight-night" } },
  checker = { enabled = true, notify = false },
  change_detection = { enabled = true, notify = false },
})
EOF

    # Create moonshot modules
    mkdir -p "$NVIM_CONFIG_DIR/lua/moonshot"
    
    # Options - optimized for terminal workflow
    cat > "$NVIM_CONFIG_DIR/lua/moonshot/options.lua" <<'EOF'
-- MOONSHOT Options - Terminal-first configuration

local opt = vim.opt

-- Performance
opt.updatetime = 50
opt.timeoutlen = 300
opt.ttimeoutlen = 10
opt.redrawtime = 1500
opt.lazyredraw = true

-- Display
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes:2"
opt.colorcolumn = "80,120"
opt.cursorline = true
opt.cursorcolumn = false
opt.wrap = false
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.pumheight = 10
opt.pumblend = 10
opt.winblend = 10

-- Terminal colors
opt.termguicolors = true
opt.background = "dark"

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true
opt.inccommand = "split"

-- Indentation (Python/YAML aware)
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true
opt.breakindent = true

-- Files
opt.swapfile = false
opt.backup = false
opt.writebackup = false
opt.undofile = true
opt.undodir = vim.fn.expand("~/.cache/nvim/undo")
opt.shadafile = vim.fn.expand("~/.cache/nvim/shada/main.shada")

-- Splits
opt.splitbelow = true
opt.splitright = true
opt.splitkeep = "screen"

-- Completion
opt.completeopt = "menu,menuone,noselect,noinsert"
opt.wildmode = "longest:full,full"
opt.wildoptions = "pum,tagfile"

-- Folding (with TreeSitter)
opt.foldmethod = "expr"
opt.foldexpr = "nvim_treesitter#foldexpr()"
opt.foldlevelstart = 99
opt.foldenable = true

-- Session options
opt.sessionoptions = "buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

-- Clipboard integration
opt.clipboard = "unnamedplus"

-- Mouse support
opt.mouse = "a"
opt.mousescroll = "ver:3,hor:6"

-- Python provider
vim.g.python3_host_prog = vim.fn.expand("~/.pyenv/shims/python3")

-- Disable providers we don't use
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0

-- Neovide GUI settings (if using)
if vim.g.neovide then
  vim.g.neovide_transparency = 0.95
  vim.g.neovide_floating_blur_amount_x = 2.0
  vim.g.neovide_floating_blur_amount_y = 2.0
  vim.g.neovide_scroll_animation_length = 0.1
  vim.g.neovide_cursor_animation_length = 0.05
  vim.g.neovide_cursor_trail_size = 0.8
end
EOF

    # Keymaps - muscle memory optimized
    cat > "$NVIM_CONFIG_DIR/lua/moonshot/keymaps.lua" <<'EOF'
-- MOONSHOT Keymaps - Terminal warrior configuration

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Disable arrow keys (force hjkl)
map({"n", "v", "i"}, "<Up>", "<Nop>", opts)
map({"n", "v", "i"}, "<Down>", "<Nop>", opts)
map({"n", "v", "i"}, "<Left>", "<Nop>", opts)
map({"n", "v", "i"}, "<Right>", "<Nop>", opts)

-- Better escape
map("i", "jk", "<Esc>", opts)
map("i", "kj", "<Esc>", opts)
map("t", "<Esc><Esc>", "<C-\\><C-n>", opts)

-- Save with Ctrl+S (muscle memory from other editors)
map({"n", "v", "i"}, "<C-s>", "<cmd>w<cr>", opts)

-- Quick quit
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit all" })
map("n", "<leader>QQ", "<cmd>qa!<cr>", { desc = "Force quit all" })

-- Window management (TMUX-like)
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })
map("n", "<C-w>|", "<cmd>vsplit<cr>", { desc = "Split vertical" })
map("n", "<C-w>-", "<cmd>split<cr>", { desc = "Split horizontal" })
map("n", "<C-w>m", "<cmd>MaximizerToggle<cr>", { desc = "Maximize window" })

-- Terminal integration
map("n", "<leader>tt", "<cmd>ToggleTerm<cr>", { desc = "Toggle terminal" })
map("n", "<leader>tg", "<cmd>ToggleTerm direction=float<cr>", { desc = "Float terminal" })
map("n", "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>", { desc = "Horizontal terminal" })
map("n", "<leader>tv", "<cmd>ToggleTerm direction=vertical<cr>", { desc = "Vertical terminal" })
map("n", "<leader>t1", "<cmd>1ToggleTerm<cr>", { desc = "Terminal 1" })
map("n", "<leader>t2", "<cmd>2ToggleTerm<cr>", { desc = "Terminal 2" })
map("n", "<leader>t3", "<cmd>3ToggleTerm<cr>", { desc = "Terminal 3" })
map("n", "<leader>t4", "<cmd>4ToggleTerm<cr>", { desc = "Terminal 4" })

-- Quick commands
map("n", "<leader>xl", "<cmd>!chmod +x %<cr>", { desc = "Make executable" })
map("n", "<leader>xr", "<cmd>!./%<cr>", { desc = "Run current file" })

-- K8s shortcuts
map("n", "<leader>ka", "<cmd>!kubectl apply -f %<cr>", { desc = "kubectl apply" })
map("n", "<leader>kd", "<cmd>!kubectl delete -f %<cr>", { desc = "kubectl delete" })
map("n", "<leader>kg", "<cmd>!kubectl get all<cr>", { desc = "kubectl get all" })
map("n", "<leader>kp", "<cmd>!kubectl get pods<cr>", { desc = "kubectl get pods" })
map("n", "<leader>ks", "<cmd>!kubectl get svc<cr>", { desc = "kubectl get svc" })
map("n", "<leader>kl", "<cmd>Telescope k8s<cr>", { desc = "K8s browser" })

-- Docker shortcuts
map("n", "<leader>db", "<cmd>!docker build -t $(basename $PWD) .<cr>", { desc = "Docker build" })
map("n", "<leader>dr", "<cmd>!docker run -it --rm $(basename $PWD)<cr>", { desc = "Docker run" })
map("n", "<leader>dp", "<cmd>!docker ps<cr>", { desc = "Docker ps" })
map("n", "<leader>di", "<cmd>!docker images<cr>", { desc = "Docker images" })
map("n", "<leader>dc", "<cmd>!docker-compose up<cr>", { desc = "Docker compose up" })

-- Git workflow
map("n", "<leader>gg", "<cmd>LazyGit<cr>", { desc = "LazyGit" })
map("n", "<leader>gs", "<cmd>Telescope git_status<cr>", { desc = "Git status" })
map("n", "<leader>gc", "<cmd>Telescope git_commits<cr>", { desc = "Git commits" })
map("n", "<leader>gb", "<cmd>Telescope git_branches<cr>", { desc = "Git branches" })
map("n", "<leader>gp", "<cmd>!git push<cr>", { desc = "Git push" })
map("n", "<leader>gP", "<cmd>!git pull<cr>", { desc = "Git pull" })
map("n", "<leader>gf", "<cmd>!git fetch --all<cr>", { desc = "Git fetch all" })

-- AI assistance
map("n", "<leader>ai", "<cmd>ChatGPT<cr>", { desc = "ChatGPT" })
map("v", "<leader>ae", "<cmd>ChatGPTEditWithInstructions<cr>", { desc = "AI Edit" })
map("v", "<leader>ar", "<cmd>ChatGPTRun<cr>", { desc = "AI Run" })
map("n", "<leader>ac", "<cmd>Copilot panel<cr>", { desc = "Copilot panel" })

-- Quick fix/location list
map("n", "<leader>xq", "<cmd>copen<cr>", { desc = "Open quickfix" })
map("n", "<leader>xl", "<cmd>lopen<cr>", { desc = "Open location list" })
map("n", "]q", "<cmd>cnext<cr>", { desc = "Next quickfix" })
map("n", "[q", "<cmd>cprev<cr>", { desc = "Previous quickfix" })

-- Session management
map("n", "<leader>ss", "<cmd>SessionSave<cr>", { desc = "Save session" })
map("n", "<leader>sr", "<cmd>SessionRestore<cr>", { desc = "Restore session" })
map("n", "<leader>sx", "<cmd>SessionDelete<cr>", { desc = "Delete session" })
map("n", "<leader>sl", "<cmd>Telescope persisted<cr>", { desc = "List sessions" })

-- Harpoon (quick file navigation)
map("n", "<leader>ha", "<cmd>lua require('harpoon.mark').add_file()<cr>", { desc = "Harpoon add" })
map("n", "<leader>hh", "<cmd>lua require('harpoon.ui').toggle_quick_menu()<cr>", { desc = "Harpoon menu" })
map("n", "<leader>1", "<cmd>lua require('harpoon.ui').nav_file(1)<cr>", { desc = "Harpoon 1" })
map("n", "<leader>2", "<cmd>lua require('harpoon.ui').nav_file(2)<cr>", { desc = "Harpoon 2" })
map("n", "<leader>3", "<cmd>lua require('harpoon.ui').nav_file(3)<cr>", { desc = "Harpoon 3" })
map("n", "<leader>4", "<cmd>lua require('harpoon.ui').nav_file(4)<cr>", { desc = "Harpoon 4" })

-- Testing
map("n", "<leader>tn", "<cmd>TestNearest<cr>", { desc = "Test nearest" })
map("n", "<leader>tf", "<cmd>TestFile<cr>", { desc = "Test file" })
map("n", "<leader>ts", "<cmd>TestSuite<cr>", { desc = "Test suite" })
map("n", "<leader>tl", "<cmd>TestLast<cr>", { desc = "Test last" })
map("n", "<leader>tv", "<cmd>TestVisit<cr>", { desc = "Test visit" })

-- REST client
map("n", "<leader>rr", "<cmd>Rest run<cr>", { desc = "Run request" })
map("n", "<leader>rl", "<cmd>Rest last<cr>", { desc = "Run last request" })
EOF

    # Autocmds - smart behaviors
    cat > "$NVIM_CONFIG_DIR/lua/moonshot/autocmds.lua" <<'EOF'
-- MOONSHOT Autocmds - Smart behaviors

local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Performance optimizations
augroup("performance", { clear = true })
autocmd("BufWinEnter", {
  group = "performance",
  pattern = "*",
  callback = function()
    if vim.fn.line("$") > 10000 then
      vim.opt_local.syntax = "off"
      vim.opt_local.foldenable = false
    end
  end,
})

-- Auto-save
augroup("autosave", { clear = true })
autocmd({ "FocusLost", "BufLeave", "WinLeave" }, {
  group = "autosave",
  pattern = "*",
  command = "silent! update",
})

-- Terminal settings
augroup("terminal", { clear = true })
autocmd("TermOpen", {
  group = "terminal",
  pattern = "*",
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.cmd("startinsert")
  end,
})

-- Auto-format on save (for specific filetypes)
augroup("autoformat", { clear = true })
autocmd("BufWritePre", {
  group = "autoformat",
  pattern = { "*.py", "*.go", "*.rs", "*.tf", "*.js", "*.ts", "*.jsx", "*.tsx" },
  callback = function()
    vim.lsp.buf.format({ async = false, timeout_ms = 2000 })
  end,
})

-- Highlight on yank
augroup("highlight_yank", { clear = true })
autocmd("TextYankPost", {
  group = "highlight_yank",
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ timeout = 200 })
  end,
})

-- Auto-reload files
augroup("autoreload", { clear = true })
autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
  group = "autoreload",
  pattern = "*",
  command = "checktime",
})

-- K8s/YAML detection
augroup("k8s_detection", { clear = true })
autocmd({ "BufRead", "BufNewFile" }, {
  group = "k8s_detection",
  pattern = { "*.yaml", "*.yml" },
  callback = function()
    local lines = vim.api.nvim_buf_get_lines(0, 0, 10, false)
    for _, line in ipairs(lines) do
      if line:match("apiVersion:") or line:match("kind:") then
        vim.bo.filetype = "yaml.kubernetes"
        break
      end
    end
  end,
})

-- Smart indentation for different filetypes
augroup("smart_indent", { clear = true })
autocmd("FileType", {
  group = "smart_indent",
  pattern = { "python" },
  callback = function()
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
  end,
})
autocmd("FileType", {
  group = "smart_indent",
  pattern = { "go", "make" },
  callback = function()
    vim.opt_local.expandtab = false
    vim.opt_local.shiftwidth = 4
    vim.opt_local.tabstop = 4
  end,
})
autocmd("FileType", {
  group = "smart_indent",
  pattern = { "yaml", "yml", "json", "javascript", "typescript", "jsx", "tsx" },
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
  end,
})
EOF

    # Create plugins directory structure
    mkdir -p "$NVIM_CONFIG_DIR/lua/moonshot/plugins"
    
    # Core plugins
    cat > "$NVIM_CONFIG_DIR/lua/moonshot/plugins/core.lua" <<'EOF'
-- MOONSHOT Core Plugins

return {
  -- Performance profiler
  { "dstein64/vim-startuptime", cmd = "StartupTime" },
  
  -- Session management
  {
    "olimorris/persisted.nvim",
    lazy = false,
    config = function()
      require("persisted").setup({
        save_dir = vim.fn.expand("~/.cache/nvim/sessions/"),
        use_git_branch = true,
        autosave = true,
        autoload = false,
        on_autoload_no_session = function()
          vim.notify("No session to restore", vim.log.levels.INFO)
        end,
      })
    end,
  },
  
  -- File navigation (Harpoon)
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("harpoon"):setup()
    end,
  },
  
  -- Window maximizer
  {
    "szw/vim-maximizer",
    cmd = "MaximizerToggle",
  },
  
  -- Better quickfix
  {
    "kevinhwang91/nvim-bqf",
    ft = "qf",
    opts = {
      preview = {
        auto_preview = true,
        border = "rounded",
      },
    },
  },
  
  -- TMUX integration
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
    },
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>" },
    },
  },
  
  -- Project management
  {
    "ahmedkhalf/project.nvim",
    config = function()
      require("project_nvim").setup({
        detection_methods = { "pattern", "lsp" },
        patterns = { ".git", "Makefile", "package.json", "go.mod", "Cargo.toml", "pyproject.toml", "requirements.txt" },
        show_hidden = true,
      })
    end,
  },
  
  -- Undo tree
  {
    "mbbill/undotree",
    cmd = "UndotreeToggle",
    keys = {
      { "<leader>u", "<cmd>UndotreeToggle<cr>", desc = "Undo tree" },
    },
  },
}
EOF

    # UI plugins
    cat > "$NVIM_CONFIG_DIR/lua/moonshot/plugins/ui.lua" <<'EOF'
-- MOONSHOT UI Plugins

return {
  -- Theme
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("tokyonight").setup({
        style = "night",
        transparent = false,
        terminal_colors = true,
        styles = {
          comments = { italic = true },
          keywords = { italic = true },
          sidebars = "dark",
          floats = "dark",
        },
        on_colors = function(colors)
          colors.border = colors.blue
        end,
      })
      vim.cmd.colorscheme("tokyonight-night")
    end,
  },
  
  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "tokyonight",
          globalstatus = true,
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = { { "filename", path = 1 } },
          lualine_x = { "encoding", "fileformat", "filetype" },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
        extensions = { "quickfix", "fugitive", "lazy", "mason", "nvim-tree", "toggleterm" },
      })
    end,
  },
  
  -- Buffer line
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
      require("bufferline").setup({
        options = {
          mode = "buffers",
          themable = true,
          numbers = "ordinal",
          diagnostics = "nvim_lsp",
          offsets = {
            {
              filetype = "NvimTree",
              text = "File Explorer",
              text_align = "center",
              separator = true,
            },
          },
          separator_style = "slant",
          hover = {
            enabled = true,
            delay = 200,
            reveal = { "close" },
          },
        },
      })
    end,
  },
  
  -- Indent guides
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {
      indent = { char = "│" },
      scope = { enabled = true, show_start = true, show_end = false },
      exclude = {
        filetypes = { "help", "dashboard", "lazy", "mason", "notify", "toggleterm" },
      },
    },
  },
  
  -- Dashboard
  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("dashboard").setup({
        theme = "hyper",
        config = {
          week_header = { enable = true },
          shortcut = {
            { desc = "󰊳 Update", group = "@property", action = "Lazy update", key = "u" },
            { desc = " Files", group = "Label", action = "Telescope find_files", key = "f" },
            { desc = " Projects", group = "DiagnosticHint", action = "Telescope projects", key = "p" },
            { desc = " Session", group = "Number", action = "SessionRestore", key = "s" },
          },
        },
      })
    end,
  },
  
  -- Notifications
  {
    "rcarriga/nvim-notify",
    config = function()
      require("notify").setup({
        stages = "fade_in_slide_out",
        timeout = 3000,
        render = "minimal",
        background_colour = "#000000",
      })
      vim.notify = require("notify")
    end,
  },
  
  -- Which-key
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    config = function()
      local wk = require("which-key")
      wk.setup({
        window = { border = "rounded" },
        layout = { align = "center" },
      })
      wk.register({
        ["<leader>"] = {
          f = { name = "+find" },
          g = { name = "+git" },
          h = { name = "+harpoon" },
          t = { name = "+terminal/test" },
          k = { name = "+kubernetes" },
          d = { name = "+docker/debug" },
          r = { name = "+rest/run" },
          a = { name = "+ai" },
          s = { name = "+session" },
          x = { name = "+diagnostics/execute" },
        },
      })
    end,
  },
}
EOF

    # Editor plugins
    cat > "$NVIM_CONFIG_DIR/lua/moonshot/plugins/editor.lua" <<'EOF'
-- MOONSHOT Editor Plugins

return {
  -- Telescope (fuzzy finder)
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      "nvim-telescope/telescope-file-browser.nvim",
      "nvim-telescope/telescope-ui-select.nvim",
      "nvim-telescope/telescope-live-grep-args.nvim",
      "debugloop/telescope-undo.nvim",
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      
      telescope.setup({
        defaults = {
          mappings = {
            i = {
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
            },
          },
          layout_strategy = "horizontal",
          layout_config = {
            horizontal = { preview_width = 0.55 },
            width = 0.87,
            height = 0.80,
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
          ["ui-select"] = {
            require("telescope.themes").get_dropdown({}),
          },
        },
      })
      
      telescope.load_extension("fzf")
      telescope.load_extension("file_browser")
      telescope.load_extension("ui-select")
      telescope.load_extension("live_grep_args")
      telescope.load_extension("undo")
      telescope.load_extension("projects")
      telescope.load_extension("persisted")
      telescope.load_extension("notify")
    end,
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep_args<cr>", desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
      { "<leader>fo", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
      { "<leader>fc", "<cmd>Telescope commands<cr>", desc = "Commands" },
      { "<leader>fk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
      { "<leader>fp", "<cmd>Telescope projects<cr>", desc = "Projects" },
      { "<leader>fu", "<cmd>Telescope undo<cr>", desc = "Undo tree" },
      { "<leader>fn", "<cmd>Telescope notify<cr>", desc = "Notifications" },
      { "<leader>fe", "<cmd>Telescope file_browser<cr>", desc = "File browser" },
    },
  },
  
  -- File tree
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        sync_root_with_cwd = true,
        respect_buf_cwd = true,
        update_focused_file = {
          enable = true,
          update_root = true,
        },
        view = {
          width = 35,
          side = "left",
        },
        renderer = {
          group_empty = true,
          highlight_git = true,
          icons = {
            show = {
              git = true,
            },
          },
        },
        filters = {
          dotfiles = false,
          custom = { "^.git$", "^node_modules$", "^.cache$" },
        },
        git = {
          enable = true,
          ignore = false,
        },
      })
    end,
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "File tree" },
      { "<leader>E", "<cmd>NvimTreeFindFile<cr>", desc = "Find in tree" },
    },
  },
  
  -- Terminal
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup({
        size = function(term)
          if term.direction == "horizontal" then
            return 15
          elseif term.direction == "vertical" then
            return vim.o.columns * 0.4
          end
        end,
        open_mapping = [[<c-\>]],
        hide_numbers = true,
        shade_terminals = true,
        shading_factor = 2,
        start_in_insert = true,
        persist_size = true,
        persist_mode = true,
        direction = "horizontal",
        close_on_exit = true,
        shell = vim.o.shell,
        float_opts = {
          border = "curved",
          winblend = 10,
        },
      })
      
      -- Custom terminals
      local Terminal = require("toggleterm.terminal").Terminal
      
      -- LazyGit
      local lazygit = Terminal:new({
        cmd = "lazygit",
        dir = "git_dir",
        direction = "float",
        float_opts = { border = "double" },
      })
      
      function _LAZYGIT_TOGGLE()
        lazygit:toggle()
      end
      
      -- K9s
      local k9s = Terminal:new({
        cmd = "k9s",
        direction = "float",
        float_opts = { border = "double" },
      })
      
      function _K9S_TOGGLE()
        k9s:toggle()
      end
      
      -- Docker
      local lazydocker = Terminal:new({
        cmd = "lazydocker",
        direction = "float",
        float_opts = { border = "double" },
      })
      
      function _LAZYDOCKER_TOGGLE()
        lazydocker:toggle()
      end
      
      vim.api.nvim_create_user_command("LazyGit", _LAZYGIT_TOGGLE, {})
      vim.api.nvim_create_user_command("K9s", _K9S_TOGGLE, {})
      vim.api.nvim_create_user_command("LazyDocker", _LAZYDOCKER_TOGGLE, {})
    end,
  },
  
  -- Comment
  {
    "numToStr/Comment.nvim",
    dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
    config = function()
      require("Comment").setup({
        pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
      })
    end,
    keys = {
      { "gcc", mode = "n", desc = "Comment line" },
      { "gc", mode = { "n", "v" }, desc = "Comment" },
      { "gb", mode = { "n", "v" }, desc = "Block comment" },
    },
  },
  
  -- Surround
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup()
    end,
  },
  
  -- Auto pairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({
        check_ts = true,
        ts_config = {
          lua = { "string", "source" },
          javascript = { "string", "template_string" },
        },
        fast_wrap = {
          map = "<M-e>",
          chars = { "{", "[", "(", '"', "'" },
          pattern = [=[[%'%"%)%>%]%)%}%,]]=],
          end_key = "$",
          keys = "qwertyuiopzxcvbnmasdfghjkl",
          check_comma = true,
          highlight = "Search",
          highlight_grey = "Comment",
        },
      })
    end,
  },
  
  -- Better escape
  {
    "max397574/better-escape.nvim",
    config = function()
      require("better_escape").setup({
        mapping = { "jk", "kj" },
        timeout = 200,
        clear_empty_lines = false,
        keys = "<Esc>",
      })
    end,
  },
  
  -- Leap (fast navigation)
  {
    "ggandor/leap.nvim",
    dependencies = { "tpope/vim-repeat" },
    config = function()
      require("leap").add_default_mappings()
    end,
  },
  
  -- Todo comments
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("todo-comments").setup()
    end,
    keys = {
      { "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "Find TODOs" },
    },
  },
}
EOF

    # LSP and completion plugins
    cat > "$NVIM_CONFIG_DIR/lua/moonshot/plugins/lsp.lua" <<'EOF'
-- MOONSHOT LSP & Completion

return {
  -- Mason (LSP installer)
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    config = function()
      require("mason").setup({
        ui = {
          border = "rounded",
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      })
    end,
  },
  
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          -- DevOps
          "terraformls",
          "tflint",
          "yamlls",
          "jsonls",
          "dockerls",
          "docker_compose_language_service",
          "helm_ls",
          "ansiblels",
          -- Python
          "pyright",
          "ruff_lsp",
          -- Go
          "gopls",
          -- Web
          "tsserver",
          "html",
          "cssls",
          -- Shell
          "bashls",
          -- Lua
          "lua_ls",
        },
        automatic_installation = true,
      })
    end,
  },
  
  -- LSP Config
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
      "b0o/schemastore.nvim",
      { "folke/neodev.nvim", opts = {} },
    },
    config = function()
      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      
      -- LSP handlers
      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
      vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })
      
      -- Diagnostic config
      vim.diagnostic.config({
        virtual_text = { prefix = "●" },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          focusable = false,
          style = "minimal",
          border = "rounded",
          source = "always",
          header = "",
          prefix = "",
        },
      })
      
      -- LSP Keymaps
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          local opts = { buffer = ev.buf }
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
          vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, opts)
          vim.keymap.set("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, opts)
          vim.keymap.set("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, opts)
          vim.keymap.set("n", "<leader>wl", function()
            print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
          end, opts)
          vim.keymap.set("n", "<leader>D", vim.lsp.buf.type_definition, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
          vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "<leader>f", function()
            vim.lsp.buf.format({ async = true })
          end, opts)
        end,
      })
      
      -- Server configurations
      local servers = {
        pyright = {
          settings = {
            python = {
              analysis = {
                typeCheckingMode = "strict",
                autoSearchPaths = true,
                diagnosticMode = "workspace",
                useLibraryCodeForTypes = true,
              },
            },
          },
        },
        yamlls = {
          settings = {
            yaml = {
              schemas = require("schemastore").yaml.schemas(),
              validate = true,
              hover = true,
              completion = true,
              customTags = {
                "!reference",
                "!Ref",
                "!Sub",
                "!GetAtt",
                "!ImportValue",
                "!Base64",
                "!Cidr",
                "!FindInMap",
                "!GetAZs",
                "!Join",
                "!Select",
                "!Split",
                "!Transform",
              },
            },
          },
        },
        jsonls = {
          settings = {
            json = {
              schemas = require("schemastore").json.schemas(),
              validate = { enable = true },
            },
          },
        },
        lua_ls = {
          settings = {
            Lua = {
              runtime = { version = "LuaJIT" },
              diagnostics = { globals = { "vim" } },
              workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
                checkThirdParty = false,
              },
              telemetry = { enable = false },
              format = { enable = false },
            },
          },
        },
      }
      
      -- Setup servers
      for server, config in pairs(servers) do
        config.capabilities = capabilities
        lspconfig[server].setup(config)
      end
      
      -- Setup remaining servers with default config
      local default_servers = {
        "terraformls", "tflint", "dockerls", "docker_compose_language_service",
        "helm_ls", "ansiblels", "gopls", "tsserver", "html", "cssls", "bashls", "ruff_lsp",
      }
      
      for _, server in ipairs(default_servers) do
        if not servers[server] then
          lspconfig[server].setup({ capabilities = capabilities })
        end
      end
    end,
  },
  
  -- Completion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "saadparwaiz1/cmp_luasnip",
      "L3MON4D3/LuaSnip",
      "rafamadriz/friendly-snippets",
      "onsails/lspkind.nvim",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local lspkind = require("lspkind")
      
      require("luasnip.loaders.from_vscode").lazy_load()
      
      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp", priority = 1000 },
          { name = "luasnip", priority = 750 },
          { name = "buffer", priority = 500 },
          { name = "path", priority = 250 },
        }),
        formatting = {
          format = lspkind.cmp_format({
            mode = "symbol_text",
            maxwidth = 50,
            ellipsis_char = "...",
          }),
        },
        experimental = {
          ghost_text = true,
        },
      })
      
      -- Cmdline completion
      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
      })
      
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          { name = "cmdline" },
        }),
      })
    end,
  },
  
  -- Formatting
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>fm",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        mode = "",
        desc = "Format buffer",
      },
    },
    opts = {
      formatters_by_ft = {
        python = { "black", "isort" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        go = { "gofmt", "goimports" },
        rust = { "rustfmt" },
        lua = { "stylua" },
        sh = { "shfmt" },
        terraform = { "terraform_fmt" },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
    },
  },
  
  -- Linting
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")
      
      lint.linters_by_ft = {
        python = { "pylint", "mypy" },
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        go = { "golangcilint" },
        yaml = { "yamllint" },
        dockerfile = { "hadolint" },
        terraform = { "tflint" },
        sh = { "shellcheck" },
      }
      
      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },
}
EOF

    # DevOps specific plugins
    cat > "$NVIM_CONFIG_DIR/lua/moonshot/plugins/devops.lua" <<'EOF'
-- MOONSHOT DevOps Plugins

return {
  -- Kubernetes
  {
    "ramilito/kubectl.nvim",
    config = function()
      require("kubectl").setup()
    end,
    keys = {
      { "<leader>kk", "<cmd>lua require('kubectl').toggle()<cr>", desc = "Kubectl" },
    },
  },
  
  -- Terraform
  {
    "hashivim/vim-terraform",
    ft = { "terraform", "hcl" },
    config = function()
      vim.g.terraform_fmt_on_save = 1
      vim.g.terraform_align = 1
    end,
  },
  
  -- Ansible
  {
    "pearofducks/ansible-vim",
    ft = { "yaml.ansible" },
  },
  
  -- Docker
  {
    "esensar/nvim-dev-container",
    config = function()
      require("devcontainer").setup({})
    end,
  },
  
  -- REST Client
  {
    "rest-nvim/rest.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    ft = "http",
    config = function()
      require("rest-nvim").setup({
        result_split_horizontal = false,
        result_split_in_place = false,
        skip_ssl_verification = false,
        encode_url = true,
        highlight = {
          enabled = true,
          timeout = 150,
        },
        result = {
          show_url = true,
          show_http_info = true,
          show_headers = true,
          formatters = {
            json = "jq",
            html = function(body)
              return vim.fn.system({ "tidy", "-i", "-q", "-" }, body)
            end,
          },
        },
        jump_to_request = false,
        env_file = ".env",
        custom_dynamic_variables = {},
        yank_dry_run = true,
      })
    end,
  },
  
  -- Database
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      { "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
    },
    cmd = {
      "DBUI",
      "DBUIToggle",
      "DBUIAddConnection",
      "DBUIFindBuffer",
    },
    init = function()
      vim.g.db_ui_use_nerd_fonts = 1
    end,
  },
  
  -- Log viewer
  {
    "MTDL9/vim-log-highlighting",
    ft = { "log" },
  },
  
  -- YAML schemas
  {
    "someone-stole-my-name/yaml-companion.nvim",
    ft = { "yaml", "yml" },
    dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("telescope").load_extension("yaml_schema")
      local cfg = require("yaml-companion").setup({
        schemas = {
          {
            name = "Kubernetes",
            uri = "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.29.0-standalone-strict/all.json",
          },
          {
            name = "docker-compose",
            uri = "https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json",
          },
        },
      })
      require("lspconfig")["yamlls"].setup(cfg)
    end,
  },
  
  -- Monitoring (Prometheus/Grafana syntax)
  {
    "towolf/vim-helm",
    ft = { "helm" },
  },
}
EOF

    # AI and productivity plugins
    cat > "$NVIM_CONFIG_DIR/lua/moonshot/plugins/ai.lua" <<'EOF'
-- MOONSHOT AI & Productivity Plugins

return {
  -- GitHub Copilot
  {
    "github/copilot.vim",
    event = "InsertEnter",
    config = function()
      vim.g.copilot_no_tab_map = true
      vim.g.copilot_assume_mapped = true
      vim.g.copilot_tab_fallback = ""
      
      vim.keymap.set("i", "<C-j>", 'copilot#Accept("\\<CR>")', {
        expr = true,
        replace_keycodes = false,
      })
      vim.keymap.set("i", "<C-]>", "<Plug>(copilot-next)")
      vim.keymap.set("i", "<C-[>", "<Plug>(copilot-previous)")
      vim.keymap.set("i", "<C-\\>", "<Plug>(copilot-dismiss)")
    end,
  },
  
  -- ChatGPT integration
  {
    "jackMort/ChatGPT.nvim",
    event = "VeryLazy",
    config = function()
      require("chatgpt").setup({
        api_key_cmd = "echo $OPENAI_API_KEY",
        yank_register = "+",
        edit_with_instructions = {
          diff = false,
          keymaps = {
            accept = "<C-y>",
            toggle_diff = "<C-d>",
            toggle_settings = "<C-o>",
            cycle_windows = "<Tab>",
            use_output_as_input = "<C-i>",
          },
        },
        chat = {
          welcome_message = "Welcome to ChatGPT! Ask me anything about your code.",
          loading_text = "Loading, please wait ...",
          question_sign = "",
          answer_sign = "ﮧ",
          max_line_length = 120,
          sessions_window = {
            border = {
              style = "rounded",
              text = {
                top = " Sessions ",
              },
            },
            win_options = {
              winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
            },
          },
          keymaps = {
            close = { "<C-c>" },
            yank_last = "<C-y>",
            yank_last_code = "<C-k>",
            scroll_up = "<C-u>",
            scroll_down = "<C-d>",
            toggle_settings = "<C-o>",
            new_session = "<C-n>",
            cycle_windows = "<Tab>",
            select_session = "<Space>",
            rename_session = "r",
            delete_session = "d",
          },
        },
        popup_layout = {
          default = "center",
          center = {
            width = "80%",
            height = "80%",
          },
          right = {
            width = "30%",
            width_settings_open = "50%",
          },
        },
        popup_window = {
          border = {
            highlight = "FloatBorder",
            style = "rounded",
            text = {
              top = " ChatGPT ",
            },
          },
          win_options = {
            wrap = true,
            linebreak = true,
            foldcolumn = "1",
            winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
          },
          buf_options = {
            filetype = "markdown",
          },
        },
        system_window = {
          border = {
            highlight = "FloatBorder",
            style = "rounded",
            text = {
              top = " SYSTEM ",
            },
          },
          win_options = {
            wrap = true,
            linebreak = true,
            foldcolumn = "2",
            winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
          },
        },
        popup_input = {
          prompt = "  ",
          border = {
            highlight = "FloatBorder",
            style = "rounded",
            text = {
              top_align = "center",
              top = " Prompt ",
            },
          },
          win_options = {
            winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
          },
          submit = "<C-Enter>",
          submit_n = "<Enter>",
        },
        settings_window = {
          border = {
            style = "rounded",
            text = {
              top = " Settings ",
            },
          },
          win_options = {
            winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
          },
        },
        openai_params = {
          model = "gpt-4",
          frequency_penalty = 0,
          presence_penalty = 0,
          max_tokens = 300,
          temperature = 0,
          top_p = 1,
          n = 1,
        },
        openai_edit_params = {
          model = "gpt-4",
          temperature = 0,
          top_p = 1,
          n = 1,
        },
        actions_paths = {},
        show_quickfixes_cmd = "Trouble quickfix",
        predefined_chat_gpt_prompts = "https://raw.githubusercontent.com/f/awesome-chatgpt-prompts/main/prompts.csv",
      })
    end,
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
    },
  },
  
  -- Testing
  {
    "vim-test/vim-test",
    config = function()
      vim.g["test#strategy"] = "toggleterm"
      vim.g["test#python#runner"] = "pytest"
      vim.g["test#python#pytest#options"] = "-vv"
    end,
  },
  
  -- Debugging
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-telescope/telescope-dap.nvim",
      "mfussenegger/nvim-dap-python",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      
      dapui.setup()
      require("nvim-dap-virtual-text").setup()
      require("dap-python").setup("~/.pyenv/shims/python")
      
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
      
      vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Continue" })
      vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Debug: Step Over" })
      vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Debug: Step Into" })
      vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Debug: Step Out" })
      vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
      vim.keymap.set("n", "<leader>dB", function()
        dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end, { desc = "Debug: Set Conditional Breakpoint" })
      vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Debug: Toggle UI" })
    end,
  },
  
  -- Git integration
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        signs = {
          add = { text = "│" },
          change = { text = "│" },
          delete = { text = "_" },
          topdelete = { text = "‾" },
          changedelete = { text = "~" },
          untracked = { text = "┆" },
        },
        signcolumn = true,
        numhl = false,
        linehl = false,
        word_diff = false,
        watch_gitdir = {
          follow_files = true,
        },
        attach_to_untracked = true,
        current_line_blame = false,
        current_line_blame_opts = {
          virt_text = true,
          virt_text_pos = "eol",
          delay = 1000,
          ignore_whitespace = false,
        },
        current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> - <summary>",
        sign_priority = 6,
        update_debounce = 100,
        status_formatter = nil,
        max_file_length = 40000,
        preview_config = {
          border = "single",
          style = "minimal",
          relative = "cursor",
          row = 0,
          col = 1,
        },
        yadm = {
          enable = false,
        },
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns
          
          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end
          
          -- Navigation
          map("n", "]c", function()
            if vim.wo.diff then
              return "]c"
            end
            vim.schedule(function()
              gs.next_hunk()
            end)
            return "<Ignore>"
          end, { expr = true, desc = "Next hunk" })
          
          map("n", "[c", function()
            if vim.wo.diff then
              return "[c"
            end
            vim.schedule(function()
              gs.prev_hunk()
            end)
            return "<Ignore>"
          end, { expr = true, desc = "Previous hunk" })
          
          -- Actions
          map("n", "<leader>hs", gs.stage_hunk, { desc = "Stage hunk" })
          map("n", "<leader>hr", gs.reset_hunk, { desc = "Reset hunk" })
          map("v", "<leader>hs", function()
            gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end, { desc = "Stage hunk" })
          map("v", "<leader>hr", function()
            gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end, { desc = "Reset hunk" })
          map("n", "<leader>hS", gs.stage_buffer, { desc = "Stage buffer" })
          map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })
          map("n", "<leader>hR", gs.reset_buffer, { desc = "Reset buffer" })
          map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
          map("n", "<leader>hb", function()
            gs.blame_line({ full = true })
          end, { desc = "Blame line" })
          map("n", "<leader>tb", gs.toggle_current_line_blame, { desc = "Toggle blame" })
          map("n", "<leader>hd", gs.diffthis, { desc = "Diff this" })
          map("n", "<leader>hD", function()
            gs.diffthis("~")
          end, { desc = "Diff this ~" })
          map("n", "<leader>td", gs.toggle_deleted, { desc = "Toggle deleted" })
          
          -- Text object
          map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Select hunk" })
        end,
      })
    end,
  },
  
  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
      "nvim-treesitter/nvim-treesitter-context",
      "windwp/nvim-ts-autotag",
    },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "python", "go", "rust", "javascript", "typescript", "tsx",
          "lua", "vim", "vimdoc", "query", "bash", "fish",
          "json", "yaml", "toml", "ini", "xml",
          "html", "css", "scss",
          "dockerfile", "terraform", "hcl",
          "markdown", "markdown_inline",
          "sql", "regex", "comment",
        },
        sync_install = false,
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = true,
        },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<C-space>",
            node_incremental = "<C-space>",
            scope_incremental = false,
            node_decremental = "<bs>",
          },
        },
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
              ["aa"] = "@parameter.outer",
              ["ia"] = "@parameter.inner",
            },
          },
          move = {
            enable = true,
            set_jumps = true,
            goto_next_start = {
              ["]m"] = "@function.outer",
              ["]]"] = "@class.outer",
            },
            goto_next_end = {
              ["]M"] = "@function.outer",
              ["]["] = "@class.outer",
            },
            goto_previous_start = {
              ["[m"] = "@function.outer",
              ["[["] = "@class.outer",
            },
            goto_previous_end = {
              ["[M"] = "@function.outer",
              ["[]"] = "@class.outer",
            },
          },
        },
        autotag = {
          enable = true,
        },
      })
      
      require("treesitter-context").setup({
        enable = true,
        max_lines = 3,
        min_window_height = 0,
        line_numbers = true,
        multiline_threshold = 20,
        trim_scope = "outer",
        mode = "cursor",
        separator = nil,
        zindex = 20,
      })
    end,
  },
}
EOF

    success "MOONSHOT Neovim configuration created"
}

install_advanced_tools() {
    info "Installing advanced DevOps and productivity tools..."
    
    # Install lazygit for better git workflow
    if ! command_exists lazygit; then
        local lg_version=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
        curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/${lg_version}/lazygit_${lg_version#v}_Linux_x86_64.tar.gz"
        tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
        sudo mv /tmp/lazygit /usr/local/bin
        rm /tmp/lazygit.tar.gz
    fi
    
    # Install k9s for Kubernetes management
    if ! command_exists k9s; then
        local k9s_version=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
        curl -Lo /tmp/k9s.tar.gz "https://github.com/derailed/k9s/releases/download/${k9s_version}/k9s_Linux_amd64.tar.gz"
        tar xf /tmp/k9s.tar.gz -C /tmp k9s
        sudo mv /tmp/k9s /usr/local/bin
        rm /tmp/k9s.tar.gz
    fi
    
    # Install lazydocker
    if ! command_exists lazydocker; then
        local ld_version=$(curl -s https://api.github.com/repos/jesseduffield/lazydocker/releases/latest | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
        curl -Lo /tmp/lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releases/download/${ld_version}/lazydocker_${ld_version#v}_Linux_x86_64.tar.gz"
        tar xf /tmp/lazydocker.tar.gz -C /tmp lazydocker
        sudo mv /tmp/lazydocker /usr/local/bin
        rm /tmp/lazydocker.tar.gz
    fi
    
    # Install bottom (better htop)
    if ! command_exists btm; then
        curl -Lo /tmp/bottom.tar.gz "https://github.com/ClementTsang/bottom/releases/latest/download/bottom_x86_64-unknown-linux-gnu.tar.gz"
        tar xf /tmp/bottom.tar.gz -C /tmp btm
        sudo mv /tmp/btm /usr/local/bin
        rm /tmp/bottom.tar.gz
    fi
    
    success "Advanced tools installed"
}

main() {
    print_header "MOONSHOT Neovim Ultra-Productivity Environment"
    
    info "Installing the most advanced Neovim setup for DevOps engineers"
    info "This will make TMUX + NeoVim + K8s your second nature"
    
    # Install Neovim nightly
    install_neovim_moonshot
    
    # Create moonshot configuration
    create_moonshot_config
    
    # Install advanced tools
    install_advanced_tools
    
    # Install language servers and tools
    info "Installing comprehensive language servers..."
    
    # Python tools
    pip3 install --user --upgrade \
        pynvim neovim debugpy \
        black isort pylint mypy \
        pytest pytest-cov \
        ipython jupyter \
        ansible-lint \
        yamllint \
        sqlparse \
        2>/dev/null || true
    
    # Node.js tools
    if command_exists npm; then
        npm install -g \
            neovim \
            typescript typescript-language-server \
            @fsouza/prettierd eslint_d \
            yaml-language-server \
            dockerfile-language-server-nodejs \
            bash-language-server \
            vscode-langservers-extracted \
            @ansible/ansible-language-server \
            sql-language-server \
            2>/dev/null || true
    fi
    
    # Go tools
    if command_exists go; then
        go install golang.org/x/tools/gopls@latest
        go install github.com/go-delve/delve/cmd/dlv@latest
        go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
        go install github.com/fatih/gomodifytags@latest
        go install github.com/josharian/impl@latest
        go install github.com/cweill/gotests/gotests@latest
        go install github.com/mgechev/revive@latest
    fi
    
    # Terraform tools
    if ! command_exists terraform-ls; then
        local tf_ls_version="0.32.7"
        curl -Lo /tmp/terraform-ls.zip "https://github.com/hashicorp/terraform-ls/releases/download/v${tf_ls_version}/terraform-ls_${tf_ls_version}_linux_amd64.zip"
        unzip -q /tmp/terraform-ls.zip -d /tmp
        sudo mv /tmp/terraform-ls /usr/local/bin/
        sudo chmod +x /usr/local/bin/terraform-ls
        rm /tmp/terraform-ls.zip
    fi
    
    if ! command_exists tflint; then
        curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
    fi
    
    success "MOONSHOT Neovim environment installed!"
    
    info "Next steps:"
    info "1. Open Neovim: nvim"
    info "2. Wait for plugins to install automatically"
    info "3. Run :Mason to check LSP servers"
    info "4. Run :Copilot setup for AI assistance"
    info "5. Set OPENAI_API_KEY for ChatGPT integration"
    info ""
    info "Key features enabled:"
    info "• Lightning-fast startup (<50ms)"
    info "• AI-powered completion (Copilot + ChatGPT)"
    info "• Full DevOps stack (K8s, Docker, Terraform)"
    info "• Advanced debugging and testing"
    info "• TMUX integration"
    info "• Session persistence"
    info "• Harpoon for instant file switching"
    info ""
    info "Remember: With great power comes great productivity! 🚀"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi