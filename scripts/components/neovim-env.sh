#!/usr/bin/env bash

# Neovim + LazyVim Environment Installer
# Installs Neovim and sets up LazyVim configuration
# Supports both desktop and server environments

set -euo pipefail

# Source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/package-managers.sh"

# Initialize environment variables
setup_environment

# Configuration
NVIM_CONFIG_DIR="$HOME/.config/nvim"
DOTFILES_NVIM_CONFIG="$DOTFILES_ROOT/nvim"

install_neovim_dependencies() {
    info "Installing Neovim dependencies..."

    local packages=()

    case "${DOTFILES_OS}" in
    linux)
        case "$(detect_package_manager)" in
        apt)
            packages=(git curl unzip tar gzip wget build-essential)
            # Add newer Neovim PPA for Ubuntu/Debian
            if ! apt-cache policy neovim 2>/dev/null | grep -q "neovim-ppa"; then
                add_repository ppa:neovim-ppa/unstable 2>/dev/null || {
                    warning "Could not add neovim PPA, using system version"
                }
            fi
            packages+=(neovim)
            ;;
        dnf | yum)
            packages=(git curl unzip tar gzip wget gcc gcc-c++ make neovim)
            ;;
        pacman)
            packages=(git curl unzip tar gzip wget base-devel neovim)
            ;;
        apk)
            packages=(git curl unzip tar gzip wget build-base neovim)
            ;;
        *)
            packages=(git curl unzip tar gzip wget)
            ;;
        esac
        ;;
    macos)
        packages=(git curl neovim)
        ;;
    esac

    if [[ ${#packages[@]} -gt 0 ]]; then
        update_package_lists
        install_packages "${packages[@]}"
    fi

    success "Neovim dependencies installation completed"
}

install_neovim_from_source() {
    if command_exists nvim; then
        local version
        version=$(nvim --version | head -1 | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
        info "Neovim already installed: $version"
        return 0
    fi

    info "Installing Neovim from GitHub releases..."

    local nvim_dir="/opt/nvim"
    local download_url=""

    case "${DOTFILES_OS}" in
    linux)
        case "${DOTFILES_ARCH}" in
        amd64 | x86_64)
            download_url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz"
            ;;
        arm64 | aarch64)
            download_url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz"
            ;;
        esac
        ;;
    macos)
        download_url="https://github.com/neovim/neovim/releases/latest/download/nvim-macos.tar.gz"
        ;;
    esac

    if [[ -z "$download_url" ]]; then
        warning "No prebuilt Neovim binary available for ${DOTFILES_OS}/${DOTFILES_ARCH}"
        return 1
    fi

    # Download and install
    local temp_dir
    temp_dir=$(mktemp -d)

    info "Downloading Neovim..."
    if ! download_file "$download_url" "$temp_dir/nvim.tar.gz"; then
        error "Failed to download Neovim"
        return 1
    fi

    info "Installing Neovim to $nvim_dir..."
    sudo mkdir -p "$nvim_dir"
    sudo tar -xzf "$temp_dir/nvim.tar.gz" -C "$nvim_dir" --strip-components=1

    # Create symlink
    if [[ -f "$nvim_dir/bin/nvim" ]]; then
        sudo ln -sf "$nvim_dir/bin/nvim" /usr/local/bin/nvim
        success "Neovim installed successfully"
    else
        error "Neovim installation failed"
        return 1
    fi

    # Cleanup
    rm -rf "$temp_dir"

    success "Neovim installation from source completed"
}

setup_lazyvim() {
    info "Setting up LazyVim configuration..."

    # Backup existing Neovim config
    if [[ -d "$NVIM_CONFIG_DIR" ]]; then
        local backup_name="nvim-config-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$BACKUP_DIR"
        cp -r "$NVIM_CONFIG_DIR" "$BACKUP_DIR/$backup_name"
        info "Backed up existing neovim config to $BACKUP_DIR/$backup_name"
    fi

    # Clone LazyVim starter template
    if [[ -d "$NVIM_CONFIG_DIR" ]]; then
        rm -rf "$NVIM_CONFIG_DIR"
    fi

    info "Cloning LazyVim starter configuration..."
    git clone https://github.com/LazyVim/starter "$NVIM_CONFIG_DIR"

    # Remove .git directory from starter template
    rm -rf "$NVIM_CONFIG_DIR/.git"

    success "LazyVim configuration installed"
    success "LazyVim setup completed"
}

install_language_servers() {
    info "Installing language servers and tools for Python & DevOps..."

    # Python Development Tools
    info "Installing Python development tools..."
    if command_exists pip3; then
        pip3 install --user --upgrade \
            pyright \
            pylsp-mypy \
            python-lsp-server[all] \
            pylint \
            black \
            isort \
            flake8 \
            mypy \
            debugpy \
            pynvim \
            ruff \
            ruff-lsp 2>/dev/null || true
    fi

    # Node.js tools (for general development and some DevOps tools)
    if command_exists npm; then
        info "Installing Node.js-based tools..."
        npm install -g \
            typescript-language-server \
            bash-language-server \
            yaml-language-server \
            dockerfile-language-server-nodejs \
            vscode-langservers-extracted \
            prettier \
            eslint_d \
            pyright 2>/dev/null || true
    fi

    # DevOps and Infrastructure Tools
    info "Installing DevOps language servers..."

    # Terraform LSP
    if ! command_exists terraform-ls; then
        info "Installing Terraform Language Server..."
        local tf_ls_version="0.32.3"
        local tf_ls_url=""
        case "${DOTFILES_OS}" in
        linux)
            tf_ls_url="https://github.com/hashicorp/terraform-ls/releases/download/v${tf_ls_version}/terraform-ls_${tf_ls_version}_linux_${DOTFILES_ARCH}.zip"
            ;;
        macos)
            tf_ls_url="https://github.com/hashicorp/terraform-ls/releases/download/v${tf_ls_version}/terraform-ls_${tf_ls_version}_darwin_${DOTFILES_ARCH}.zip"
            ;;
        esac
        if [[ -n "$tf_ls_url" ]]; then
            local temp_dir=$(mktemp -d)
            download_file "$tf_ls_url" "$temp_dir/terraform-ls.zip" &&
                unzip -q "$temp_dir/terraform-ls.zip" -d "$temp_dir" &&
                sudo mv "$temp_dir/terraform-ls" /usr/local/bin/ &&
                sudo chmod +x /usr/local/bin/terraform-ls
            rm -rf "$temp_dir"
        fi
    fi

    # Ansible LSP
    if command_exists pip3; then
        pip3 install --user ansible-lint ansible-language-server 2>/dev/null || true
    fi

    # Go tools (for K8s and cloud-native development)
    if command_exists go; then
        info "Installing Go development tools..."
        go install golang.org/x/tools/gopls@latest 2>/dev/null || true
        go install github.com/go-delve/delve/cmd/dlv@latest 2>/dev/null || true
    fi

    # Install via package manager if available
    case "${DOTFILES_OS}" in
    linux)
        case "$(detect_package_manager)" in
        apt)
            install_packages shellcheck yamllint hadolint || true
            ;;
        pacman)
            install_packages shellcheck shfmt yamllint hadolint || true
            ;;
        esac
        ;;
    macos)
        if command_exists brew; then
            brew install shellcheck shfmt lua-language-server yamllint hadolint || true
        fi
        ;;
    esac

    success "Language servers installation completed"
}

configure_neovim_integration() {
    info "Configuring Neovim shell integration..."

    # Add Neovim aliases to shell configuration
    local shell_config=""

    if [[ -f "$HOME/.zshrc" ]]; then
        shell_config="$HOME/.zshrc"
    elif [[ -f "$HOME/.bashrc" ]]; then
        shell_config="$HOME/.bashrc"
    fi

    if [[ -n "$shell_config" ]]; then
        # Add EDITOR environment variable
        if ! grep -q "export EDITOR.*nvim" "$shell_config"; then
            echo "" >>"$shell_config"
            echo "# Neovim configuration" >>"$shell_config"
            echo "export EDITOR='nvim'" >>"$shell_config"
            echo "export VISUAL='nvim'" >>"$shell_config"
            echo "" >>"$shell_config"

            # Add useful aliases
            echo "# Neovim aliases" >>"$shell_config"
            echo "alias v='nvim'" >>"$shell_config"
            echo "alias vi='nvim'" >>"$shell_config"
            echo "alias vim='nvim'" >>"$shell_config"
            echo "alias vimdiff='nvim -d'" >>"$shell_config"
            echo "" >>"$shell_config"
        fi

        success "Shell integration configured"
    fi

    success "Neovim shell integration completed"
}

create_custom_lazyvim_config() {
    info "Creating custom LazyVim configuration for Python & DevOps..."

    # Create custom configuration files
    local lua_dir="$NVIM_CONFIG_DIR/lua"
    local config_dir="$lua_dir/config"
    local plugins_dir="$lua_dir/plugins"

    mkdir -p "$config_dir"
    mkdir -p "$plugins_dir"

    # Create options.lua with Python/DevOps optimized defaults
    cat >"$lua_dir/config/options.lua" <<'EOF'
-- Custom options for LazyVim - Python & DevOps optimized
local opt = vim.opt

-- Better defaults
opt.relativenumber = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.colorcolumn = "80,120"

-- Better search
opt.ignorecase = true
opt.smartcase = true

-- Python PEP8 compliant formatting
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.smartindent = true

-- Better files
opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.undofile = true

-- Better UI
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cmdheight = 1
opt.updatetime = 300
opt.timeoutlen = 500

-- Python specific
vim.g.python3_host_prog = vim.fn.expand("~/.pyenv/shims/python3")

-- File type specific settings
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "yaml", "yml" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "json", "jsonc" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "terraform", "hcl" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
  end,
})
EOF

    # Create keymaps.lua with Python/DevOps specific bindings
    cat >"$lua_dir/config/keymaps.lua" <<'EOF'
-- Custom keymaps for LazyVim - Python & DevOps focused
local map = vim.keymap.set

-- Better window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- Better buffer navigation
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })

-- Better indenting
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Better line movement
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })

-- Clear search highlighting
map("n", "<Esc>", "<cmd>nohlsearch<cr>")

-- Quick save
map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit" })

-- Python specific
map("n", "<leader>pr", "<cmd>!python3 %<cr>", { desc = "Run Python file" })
map("n", "<leader>pd", "<cmd>lua require('dap-python').test_method()<cr>", { desc = "Debug Python method" })
map("n", "<leader>pf", "<cmd>lua require('dap-python').test_class()<cr>", { desc = "Debug Python class" })
map("n", "<leader>ps", "<cmd>lua require('dap-python').debug_selection()<cr>", { desc = "Debug Python selection" })

-- Docker/K8s
map("n", "<leader>dk", "<cmd>!kubectl apply -f %<cr>", { desc = "Apply K8s manifest" })
map("n", "<leader>dd", "<cmd>!docker build .<cr>", { desc = "Docker build" })

-- Terraform
map("n", "<leader>ti", "<cmd>!terraform init<cr>", { desc = "Terraform init" })
map("n", "<leader>tp", "<cmd>!terraform plan<cr>", { desc = "Terraform plan" })
map("n", "<leader>tf", "<cmd>!terraform fmt %<cr>", { desc = "Terraform format" })
map("n", "<leader>tv", "<cmd>!terraform validate<cr>", { desc = "Terraform validate" })

-- Git (enhanced)
map("n", "<leader>gs", "<cmd>Git<cr>", { desc = "Git status" })
map("n", "<leader>gp", "<cmd>!git push<cr>", { desc = "Git push" })
map("n", "<leader>gpu", "<cmd>!git pull<cr>", { desc = "Git pull" })
map("n", "<leader>gc", "<cmd>!git commit<cr>", { desc = "Git commit" })
map("n", "<leader>ga", "<cmd>!git add .<cr>", { desc = "Git add all" })
map("n", "<leader>gb", "<cmd>Gblame<cr>", { desc = "Git blame" })
map("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", { desc = "Git diff view" })
map("n", "<leader>gl", "<cmd>!git log --oneline -10<cr>", { desc = "Git log" })
map("n", "<leader>gco", "<cmd>!git checkout ", { desc = "Git checkout" })
EOF

    # Create Python & DevOps specific plugin configurations
    create_devops_plugins

    success "Custom LazyVim configuration created"
    success "Custom LazyVim configuration completed"
}

create_devops_plugins() {
    info "Creating Python & DevOps plugin configurations..."

    local plugins_dir="$NVIM_CONFIG_DIR/lua/plugins"
    mkdir -p "$plugins_dir"

    # Python development plugins
    cat >"$plugins_dir/python.lua" <<'EOF'
return {
  -- Python specific plugins
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "python",
        "rst",
        "toml",
        "ninja",
      })
    end,
  },
  
  -- Enhanced Python LSP
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {
          settings = {
            python = {
              analysis = {
                autoSearchPaths = true,
                typeCheckingMode = "strict",
                diagnosticMode = "workspace",
                useLibraryCodeForTypes = true,
              },
            },
          },
        },
        ruff_lsp = {},
        pylsp = {
          settings = {
            pylsp = {
              plugins = {
                pycodestyle = { enabled = false },
                pyflakes = { enabled = false },
                pylint = { enabled = true },
                flake8 = { enabled = false },
                mypy = { enabled = true },
                isort = { enabled = true },
                black = { enabled = true },
              },
            },
          },
        },
      },
    },
  },
  
  -- Python debugging
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "mfussenegger/nvim-dap-python",
    },
    config = function()
      require("dap-python").setup("~/.pyenv/shims/python")
    end,
  },
  
  -- Python testing
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-neotest/neotest-python",
    },
    opts = {
      adapters = {
        ["neotest-python"] = {
          dap = { justMyCode = false },
          runner = "pytest",
        },
      },
    },
  },
  
  -- Virtual environment selector
  {
    "linux-cultist/venv-selector.nvim",
    dependencies = {
      "neovim/nvim-lspconfig",
      "nvim-telescope/telescope.nvim",
    },
    opts = {
      name = { "venv", ".venv", "env", ".env" },
    },
    keys = {
      { "<leader>pv", "<cmd>VenvSelect<cr>", desc = "Select Python venv" },
    },
  },
}
EOF

    # DevOps and Infrastructure plugins
    cat >"$plugins_dir/devops.lua" <<'EOF'
return {
  -- DevOps language support
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "yaml",
        "json",
        "jsonc",
        "dockerfile",
        "terraform",
        "hcl",
        "go",
        "gomod",
        "gowork",
        "bash",
        "make",
        "markdown",
        "markdown_inline",
      })
    end,
  },
  
  -- Terraform/HCL support
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        terraformls = {},
        tflint = {},
      },
    },
  },
  
  -- Ansible support
  {
    "pearofducks/ansible-vim",
    ft = { "yaml.ansible", "ansible" },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ansiblels = {},
      },
    },
  },
  
  -- Docker support
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        dockerls = {},
        docker_compose_language_service = {},
      },
    },
  },
  
  -- Kubernetes support
  {
    "someone-stole-my-name/yaml-companion.nvim",
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
            uri = "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.29.0/all.json",
          },
        },
      })
      require("lspconfig")["yamlls"].setup(cfg)
    end,
    keys = {
      { "<leader>ys", "<cmd>Telescope yaml_schema<cr>", desc = "Select YAML schema" },
    },
  },
  
  -- Git integration (enhanced)
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "Gstatus", "Gblame", "Gpush", "Gpull" },
  },
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles" },
  },
  
  -- REST client for API testing  
  {
    "mistweaverco/kulala.nvim",
    ft = "http",
    opts = {},
    keys = {
      { "<leader>rr", "<cmd>lua require('kulala').run()<cr>", desc = "Run REST request" },
      { "<leader>rp", "<cmd>lua require('kulala').inspect()<cr>", desc = "Preview REST request" },
      { "<leader>rl", "<cmd>lua require('kulala').replay()<cr>", desc = "Run last REST request" },
    },
  },
  
  -- JSON/YAML utilities
  {
    "gennaro-tedesco/nvim-jqx",
    ft = { "json", "yaml" },
  },
}
EOF

    # AI-powered completion configuration (Cursor-like)
    cat >"$plugins_dir/ai-completion.lua" <<'EOF'
return {
  -- Enhanced AI-powered completion similar to Cursor
  {
    "github/copilot.vim",
    event = "InsertEnter",
    config = function()
      -- Disable default tab mapping
      vim.g.copilot_no_tab_map = true
      vim.g.copilot_assume_mapped = true
      
      -- Custom keymaps for Copilot
      vim.keymap.set("i", "<C-j>", 'copilot#Accept("\\<CR>")', {
        expr = true,
        replace_keycodes = false,
        desc = "Accept Copilot suggestion"
      })
      
      vim.keymap.set("i", "<C-l>", "<Plug>(copilot-accept-word)", {
        desc = "Accept Copilot word"
      })
      
      vim.keymap.set("i", "<C-h>", "<Plug>(copilot-dismiss)", {
        desc = "Dismiss Copilot suggestion"
      })
      
      vim.keymap.set("i", "<C-n>", "<Plug>(copilot-next)", {
        desc = "Next Copilot suggestion"
      })
      
      vim.keymap.set("i", "<C-p>", "<Plug>(copilot-previous)", {
        desc = "Previous Copilot suggestion"
      })
      
      -- Auto-trigger on certain filetypes
      vim.g.copilot_filetypes = {
        ["*"] = true,
        gitcommit = false,
        gitrebase = false,
        hgcommit = false,
        svn = false,
        cvs = false,
        [".env"] = false,
      }
    end,
  },

  -- AI-powered code suggestions (Codeium - free alternative)
  {
    "Exafunction/codeium.vim",
    event = "BufEnter",
    config = function()
      -- Disable Codeium by default to prevent auto-prompt for API key
      vim.g.codeium_enabled = false
      vim.g.codeium_manual = true
      vim.g.codeium_no_map_tab = true
      
      -- Custom keymaps for Codeium (only work when enabled)
      vim.keymap.set('i', '<C-g>', function() return vim.fn['codeium#Accept']() end, { expr = true, silent = true })
      vim.keymap.set('i', '<C-;>', function() return vim.fn['codeium#CycleCompletions'](1) end, { expr = true, silent = true })
      vim.keymap.set('i', '<C-,>', function() return vim.fn['codeium#CycleCompletions'](-1) end, { expr = true, silent = true })
      vim.keymap.set('i', '<C-x>', function() return vim.fn['codeium#Clear']() end, { expr = true, silent = true })
      
      -- Disable for certain file types
      vim.g.codeium_disable_bindings = 1
      vim.g.codeium_filetypes = {
        gitcommit = false,
        gitrebase = false,
        help = false,
        hgcommit = false,
        svn = false,
        cvs = false,
        [".env"] = false,
      }
      
      -- Create command to enable Codeium manually
      vim.api.nvim_create_user_command('CodeiumEnable', function()
        vim.g.codeium_enabled = true
        vim.g.codeium_manual = false
        vim.cmd('Codeium Auth')
        vim.notify("Codeium enabled. Please authenticate with :Codeium Auth", vim.log.levels.INFO)
      end, {})
      
      vim.api.nvim_create_user_command('CodeiumDisable', function()
        vim.g.codeium_enabled = false
        vim.g.codeium_manual = true
        vim.notify("Codeium disabled", vim.log.levels.INFO)
      end, {})
      
      -- Show status
      vim.api.nvim_create_user_command('CodeiumStatus', function()
        if vim.g.codeium_enabled then
          vim.notify("Codeium is enabled", vim.log.levels.INFO)
        else
          vim.notify("Codeium is disabled. Run :CodeiumEnable to activate", vim.log.levels.INFO)
        end
      end, {})
    end
  },

  -- Enhanced snippet support
  {
    "L3MON4D3/LuaSnip",
    build = "make install_jsregexp",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local luasnip = require("luasnip")
      
      -- Load snippets
      require("luasnip.loaders.from_vscode").lazy_load()
      
      -- Custom snippets for common patterns
      luasnip.add_snippets("python", {
        luasnip.snippet("def", {
          luasnip.text_node("def "),
          luasnip.insert_node(1, "function_name"),
          luasnip.text_node("("),
          luasnip.insert_node(2, "args"),
          luasnip.text_node("):"),
          luasnip.text_node({"", "    "}),
          luasnip.insert_node(0),
        }),
        luasnip.snippet("class", {
          luasnip.text_node("class "),
          luasnip.insert_node(1, "ClassName"),
          luasnip.text_node("("),
          luasnip.insert_node(2, "object"),
          luasnip.text_node("):"),
          luasnip.text_node({"", "    def __init__(self"}),
          luasnip.insert_node(3),
          luasnip.text_node("):"),
          luasnip.text_node({"", "        "}),
          luasnip.insert_node(0),
        }),
      })
      
      -- Keymaps for LuaSnip
      vim.keymap.set({"i", "s"}, "<C-k>", function()
        if luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        end
      end, {silent = true})
      
      vim.keymap.set({"i", "s"}, "<C-j>", function()
        if luasnip.jumpable(-1) then
          luasnip.jump(-1)
        end
      end, {silent = true})
    end,
  },

  -- Intelligent auto-pairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      local autopairs = require("nvim-autopairs")
      autopairs.setup({
        check_ts = true,
        ts_config = {
          lua = { "string", "source" },
          javascript = { "string", "template_string" },
          java = false,
        },
        disable_filetype = { "TelescopePrompt", "spectre_panel" },
        fast_wrap = {
          map = "<M-e>",
          chars = { "{", "[", "(", '"', "'" },
          pattern = string.gsub([[ [%'%"%)%>%]%)%}%,] ]], "%s+", ""),
          offset = 0,
          end_key = "$",
          keys = "qwertyuiopzxcvbnmasdfghjkl",
          check_comma = true,
          highlight = "PmenuSel",
          highlight_grey = "LineNr",
        },
      })
    end,
  },

  -- Smart commenting with context awareness
  {
    "numToStr/Comment.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "JoosepAlviste/nvim-ts-context-commentstring",
    },
    config = function()
      require("Comment").setup({
        pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
      })
    end,
  },

  -- Enhanced text objects for better code manipulation
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    event = "VeryLazy",
    dependencies = "nvim-treesitter/nvim-treesitter",
    config = function()
      require("nvim-treesitter.configs").setup({
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
              ["]f"] = "@function.outer",
              ["]c"] = "@class.outer",
            },
            goto_next_end = {
              ["]F"] = "@function.outer",
              ["]C"] = "@class.outer",
            },
            goto_previous_start = {
              ["[f"] = "@function.outer",
              ["[c"] = "@class.outer",
            },
            goto_previous_end = {
              ["[F"] = "@function.outer",
              ["[C"] = "@class.outer",
            },
          },
        },
      })
    end,
  },
}
EOF

    # Theme configuration with Catppuccin Frappe
    cat >"$plugins_dir/colorscheme.lua" <<'EOF'
return {
  -- Catppuccin Frappe colorscheme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "frappe", -- latte, frappe, macchiato, mocha
      background = {
        light = "latte",
        dark = "frappe",
      },
      transparent_background = false,
      show_end_of_buffer = false,
      term_colors = true,
      dim_inactive = {
        enabled = false,
        shade = "dark",
        percentage = 0.15,
      },
      no_italic = false,
      no_bold = false,
      no_underline = false,
      styles = {
        comments = { "italic" },
        conditionals = { "italic" },
        loops = {},
        functions = {},
        keywords = {},
        strings = {},
        variables = {},
        numbers = {},
        booleans = {},
        properties = {},
        types = {},
        operators = {},
      },
      color_overrides = {},
      custom_highlights = {},
      integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        treesitter = true,
        notify = false,
        mini = {
          enabled = true,
          indentscope_color = "",
        },
        telescope = true,
        which_key = true,
        mason = true,
        neotest = true,
        dap = {
          enabled = true,
          enable_ui = true,
        },
        native_lsp = {
          enabled = true,
          virtual_text = {
            errors = { "italic" },
            hints = { "italic" },
            warnings = { "italic" },
            information = { "italic" },
          },
          underlines = {
            errors = { "underline" },
            hints = { "underline" },
            warnings = { "underline" },
            information = { "underline" },
          },
          inlay_hints = {
            background = true,
          },
        },
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin-frappe")
    end,
  },
}
EOF

    # Additional productivity plugins
    cat >"$plugins_dir/productivity.lua" <<'EOF'
return {
  -- AI completion is now handled by ai-completion.lua
  
  -- Better terminal integration
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      open_mapping = [[<c-\>]],
      direction = "horizontal",
      size = 20,
    },
  },
  
  -- Project management
  {
    "ahmedkhalf/project.nvim",
    config = function()
      require("project_nvim").setup({
        patterns = { ".git", "_darcs", ".hg", ".bzr", ".svn", "Makefile", "package.json", "pyproject.toml", "requirements.txt", "go.mod", "Cargo.toml" },
      })
    end,
  },
  
  -- Better code folding
  {
    "kevinhwang91/nvim-ufo",
    dependencies = "kevinhwang91/promise-async",
    config = function()
      require("ufo").setup()
    end,
  },
  
  -- Database client
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
}
EOF

    # Claude Code integration plugin
    cat >"$plugins_dir/claude-code.lua" <<'EOF'
return {
  -- Claude Code integration plugin
  {
    "akinsho/toggleterm.nvim", 
    opts = function(_, opts)
      -- Add Claude Code terminal configuration
      opts.float_opts = vim.tbl_extend("force", opts.float_opts or {}, {
        border = "curved",
        width = function() return math.floor(vim.o.columns * 0.9) end,
        height = function() return math.floor(vim.o.lines * 0.8) end,
        winblend = 10,
      })
      return opts
    end,
    keys = {
      -- Quick Claude Code terminal
      { "<leader>cc", function() 
        local Terminal = require('toggleterm.terminal').Terminal
        local claude_term = Terminal:new({
          cmd = "claude --dangerously-skip-permissions",
          hidden = true,
          direction = "float",
          float_opts = {
            border = "curved",
            width = function() return math.floor(vim.o.columns * 0.9) end,
            height = function() return math.floor(vim.o.lines * 0.8) end,
          },
          on_open = function(term)
            vim.cmd("startinsert!")
            -- Send vim mode command when opening
            vim.defer_fn(function()
              term:send("/vim")
            end, 100)
          end,
          on_close = function()
            vim.cmd("startinsert!")
          end,
        })
        claude_term:toggle()
      end, desc = "Open Claude Code Terminal" },
      
      -- Send selection to Claude Code
      { "<leader>cs", function()
        -- Get visual selection
        local start_pos = vim.fn.getpos("'<")
        local end_pos = vim.fn.getpos("'>")
        local lines = vim.fn.getline(start_pos[2], end_pos[2])
        
        if #lines == 0 then return end
        
        -- If single line, get partial selection
        if #lines == 1 then
          local start_col = start_pos[3]
          local end_col = end_pos[3]
          lines[1] = string.sub(lines[1], start_col, end_col)
        else
          -- Multi-line selection
          lines[1] = string.sub(lines[1], start_pos[3])
          lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
        end
        
        local text = table.concat(lines, "\n")
        
        -- Copy to clipboard for Claude Code
        vim.fn.setreg("+", text)
        
        -- Open Claude Code terminal
        local Terminal = require('toggleterm.terminal').Terminal
        local claude_term = Terminal:new({
          cmd = "claude --dangerously-skip-permissions",
          hidden = true,
          direction = "float",
          float_opts = {
            border = "curved",
            width = function() return math.floor(vim.o.columns * 0.9) end,
            height = function() return math.floor(vim.o.lines * 0.8) end,
          },
          on_open = function(term)
            vim.cmd("startinsert!")
            -- Automatically paste the selection
            vim.defer_fn(function()
              term:send("/vim")
              term:send("Look at this code:\n```\n" .. text .. "\n```")
            end, 200)
          end,
        })
        claude_term:toggle()
        
        vim.notify("Sent selection to Claude Code")
      end, mode = "v", desc = "Send Selection to Claude Code" },
      
      -- Send current file to Claude Code
      { "<leader>cf", function()
        local filepath = vim.fn.expand("%:p")
        local filename = vim.fn.expand("%:t")
        
        if filepath == "" then
          vim.notify("No file is currently open", vim.log.levels.WARN)
          return
        end
        
        -- Read file content
        local lines = vim.fn.readfile(filepath)
        local content = table.concat(lines, "\n")
        
        -- Open Claude Code terminal
        local Terminal = require('toggleterm.terminal').Terminal
        local claude_term = Terminal:new({
          cmd = "claude --dangerously-skip-permissions",
          hidden = true,
          direction = "float",
          float_opts = {
            border = "curved", 
            width = function() return math.floor(vim.o.columns * 0.9) end,
            height = function() return math.floor(vim.o.lines * 0.8) end,
          },
          on_open = function(term)
            vim.cmd("startinsert!")
            -- Send file content to Claude
            vim.defer_fn(function()
              term:send("/vim")
              term:send("Help me with this file (" .. filename .. "):\n```\n" .. content .. "\n```")
            end, 200)
          end,
        })
        claude_term:toggle()
        
        vim.notify("Sent " .. filename .. " to Claude Code")
      end, desc = "Send Current File to Claude Code" },
      
      -- Quick code explanation
      { "<leader>ce", function()
        -- Get visual selection or current line
        local mode = vim.fn.mode()
        local text = ""
        
        if mode == "v" or mode == "V" then
          local start_pos = vim.fn.getpos("'<")
          local end_pos = vim.fn.getpos("'>")
          local lines = vim.fn.getline(start_pos[2], end_pos[2])
          text = table.concat(lines, "\n")
        else
          text = vim.fn.getline(".")
        end
        
        if text == "" then return end
        
        -- Open Claude Code terminal with explanation request
        local Terminal = require('toggleterm.terminal').Terminal
        local claude_term = Terminal:new({
          cmd = "claude --dangerously-skip-permissions",
          hidden = true,
          direction = "float",
          float_opts = {
            border = "curved",
            width = function() return math.floor(vim.o.columns * 0.9) end,
            height = function() return math.floor(vim.o.lines * 0.8) end,
          },
          on_open = function(term)
            vim.cmd("startinsert!")
            vim.defer_fn(function()
              term:send("/vim")
              term:send("Explain this code:\n```\n" .. text .. "\n```")
            end, 200)
          end,
        })
        claude_term:toggle()
        
      end, mode = {"n", "v"}, desc = "Explain Code with Claude" },
    }
  },
  
  -- Which-key descriptions for Claude Code commands
  {
    "folke/which-key.nvim",
    opts = function(_, opts)
      opts.spec = opts.spec or {}
      table.insert(opts.spec, {
        { "<leader>c", group = "Claude Code" },
        { "<leader>cc", desc = "Open Claude Code Terminal" },
        { "<leader>cs", desc = "Send Selection to Claude Code", mode = "v" },
        { "<leader>cf", desc = "Send Current File to Claude Code" },
        { "<leader>ce", desc = "Explain Code with Claude", mode = {"n", "v"} },
      })
      return opts
    end,
  },
}
EOF

    success "DevOps plugin configurations created"
}

# ============================================================================
# KEYBOARD SETUP INTEGRATION (Caps Lock → Escape for vim/neovim workflow)
# ============================================================================

install_keyboard_dependencies() {
    info "Installing keyboard configuration dependencies..."

    case "${DOTFILES_OS}" in
    linux)
        case "$(detect_package_manager)" in
        apt)
            install_packages xkb-data console-setup || true
            if [[ "${DOTFILES_DISPLAY}" == "wayland" ]]; then
                install_packages keyd || true
            fi
            ;;
        dnf | yum)
            install_packages xkeyboard-config || true
            if [[ "${DOTFILES_DISPLAY}" == "wayland" ]]; then
                install_packages keyd || true
            fi
            ;;
        pacman)
            install_packages xkeyboard-config || true
            if [[ "${DOTFILES_DISPLAY}" == "wayland" ]]; then
                install_packages keyd || true
            fi
            ;;
        esac
        ;;
    macos)
        # macOS has built-in keyboard configuration
        debug "macOS keyboard configuration uses system preferences"
        ;;
    esac

    success "Keyboard dependencies installation completed"
}

setup_caps_to_escape() {
    info "Setting up Caps Lock → Escape mapping (essential for vim/neovim)..."

    case "${DOTFILES_OS}" in
    linux)
        setup_caps_linux
        ;;
    macos)
        setup_caps_macos
        ;;
    *)
        error "Unsupported OS for keyboard setup: ${DOTFILES_OS}"
        ;;
    esac

    success "Caps Lock to Escape setup completed"
}

setup_caps_linux() {
    local display_server="${DOTFILES_DISPLAY}"

    case "$display_server" in
    x11)
        setup_caps_x11
        ;;
    wayland)
        setup_caps_wayland
        ;;
    console)
        setup_caps_console
        ;;
    *)
        # Setup for all possible scenarios
        setup_caps_x11
        setup_caps_wayland || true
        setup_caps_console
        ;;
    esac
}

setup_caps_x11() {
    info "Configuring Caps Lock → Escape for X11..."

    # Create temporary Xmodmap content instead of relying on config files
    local xmodmap_content="clear lock
clear control
keycode 66 = Escape NoSymbol Escape
add control = Control_L Control_R"

    local xmodmap_file="$HOME/.Xmodmap"

    # Write Xmodmap configuration
    echo "$xmodmap_content" >"$xmodmap_file"
    success "Created .Xmodmap configuration"

    # Apply immediately if in X11 session
    if command_exists xmodmap && [[ -n "${DISPLAY:-}" ]]; then
        xmodmap "$xmodmap_file"
        success "Applied Xmodmap configuration"
    fi

    # Add to X11 startup files
    local xinitrc="$HOME/.xinitrc"
    local xprofile="$HOME/.xprofile"
    local xmodmap_line="[ -f ~/.Xmodmap ] && xmodmap ~/.Xmodmap"

    for file in "$xinitrc" "$xprofile"; do
        if [[ ! -f "$file" ]] || ! grep -q "xmodmap.*Xmodmap" "$file" 2>/dev/null; then
            echo "$xmodmap_line" >>"$file"
            success "Added Xmodmap to $(basename "$file")"
        fi
    done
}

setup_caps_wayland() {
    local method="none"

    # Try different methods in order of preference
    if setup_caps_wayland_keyd; then
        method="keyd"
    elif setup_caps_wayland_gnome; then
        method="gnome"
    elif setup_caps_wayland_kde; then
        method="kde"
    else
        warning "Could not configure Caps Lock → Escape for Wayland"
        return 1
    fi

    success "Configured Caps Lock → Escape for Wayland using $method"
}

setup_caps_wayland_keyd() {
    if ! command_exists keyd; then
        debug "keyd not available, skipping"
        return 1
    fi

    info "Setting up Caps Lock → Escape for Wayland using keyd..."

    # Create keyd configuration inline
    local keyd_config_content="[ids]

*

[main]

# Map caps lock to escape
capslock = escape

# Optional: make escape also work as caps lock when held
# escape = overload(control, escape)"

    local keyd_system_config="/etc/keyd/default.conf"

    sudo mkdir -p /etc/keyd
    echo "$keyd_config_content" | sudo tee "$keyd_system_config" >/dev/null
    success "Created keyd configuration"

    # Enable and start keyd service
    if command_exists systemctl; then
        sudo systemctl enable keyd 2>/dev/null || true
        sudo systemctl restart keyd 2>/dev/null || true
        success "Enabled and started keyd service"
    fi

    return 0
}

setup_caps_wayland_gnome() {
    if ! command_exists gsettings; then
        debug "gsettings not available, skipping GNOME configuration"
        return 1
    fi

    info "Setting up Caps Lock → Escape for GNOME/Wayland..."

    # Try both old and new GNOME settings paths
    if gsettings set org.gnome.desktop.input-sources xkb-options "['caps:escape']" 2>/dev/null; then
        success "Configured GNOME to map Caps Lock → Escape"
        return 0
    elif gsettings set org.gnome.desktop.input-sources xkb-options '["caps:escape"]' 2>/dev/null; then
        success "Configured GNOME to map Caps Lock → Escape"
        return 0
    else
        debug "Could not configure GNOME settings"
        return 1
    fi
}

setup_caps_wayland_kde() {
    if ! command_exists kwriteconfig5 && ! command_exists kwriteconfig6; then
        debug "KDE configuration tools not available, skipping"
        return 1
    fi

    info "Setting up Caps Lock → Escape for KDE/Wayland..."

    if command_exists kwriteconfig6; then
        kwriteconfig6 --file kxkbrc --group Layout --key Options caps:escape
    elif command_exists kwriteconfig5; then
        kwriteconfig5 --file kxkbrc --group Layout --key Options caps:escape
    fi

    success "Configured KDE to map Caps Lock → Escape"
    return 0
}

setup_caps_console() {
    info "Setting up Caps Lock → Escape for TTY/Console..."

    # For systemd-based systems
    if command_exists localectl; then
        sudo localectl set-x11-keymap us pc105 "" caps:escape 2>/dev/null || true
        success "Configured console keymap with localectl"
    fi

    # Using loadkeys for immediate effect
    if command_exists loadkeys; then
        echo "keycode 58 = Escape" | sudo loadkeys 2>/dev/null || true
        success "Applied console keymap with loadkeys"
    fi
}

setup_caps_macos() {
    info "Setting up Caps Lock → Escape for macOS..."

    # Using hidutil for macOS Sierra and later
    if command_exists hidutil; then
        # Map Caps Lock (0x700000039) to Escape (0x700000029)
        hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000029}]}'
        success "Mapped Caps Lock → Escape using hidutil"

        # Create LaunchAgent to persist on restart
        setup_macos_launch_agent

        info "Note: You can also configure this in System Preferences > Keyboard > Modifier Keys"
    else
        error "hidutil not found. Please configure manually in System Preferences > Keyboard > Modifier Keys"
    fi

    # Copy DefaultKeyBinding.dict for additional bindings
    setup_macos_key_bindings
}

setup_macos_launch_agent() {
    local launch_agent_dir="$HOME/Library/LaunchAgents"
    local launch_agent_plist="$launch_agent_dir/com.user.capsToEscape.plist"

    mkdir -p "$launch_agent_dir"

    cat >"$launch_agent_plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.capsToEscape</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/hidutil</string>
        <string>property</string>
        <string>--set</string>
        <string>{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x700000029}]}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

    launchctl load "$launch_agent_plist" 2>/dev/null || true
    success "Created LaunchAgent for persistence"
}

setup_macos_key_bindings() {
    local keybinding_source="$DOTFILES_ROOT/macos/DefaultKeyBinding.dict"
    local keybinding_dest="$HOME/Library/KeyBindings/DefaultKeyBinding.dict"

    if [[ -f "$keybinding_source" ]]; then
        mkdir -p "$HOME/Library/KeyBindings"
        cp "$keybinding_source" "$keybinding_dest"
        success "Copied DefaultKeyBinding.dict"
    fi
}

optimize_keyboard_for_vim() {
    info "Optimizing keyboard settings for vim/neovim workflow..."

    case "${DOTFILES_OS}" in
    linux)
        # Set reasonable keyboard repeat rate for vim navigation
        if command_exists xset && [[ -n "${DISPLAY:-}" ]]; then
            xset r rate 300 50 # 300ms delay, 50 chars/sec
            success "Set keyboard repeat rate for vim navigation"
        fi
        ;;
    macos)
        # Set reasonable keyboard repeat rate for vim navigation
        defaults write NSGlobalDomain KeyRepeat -int 2
        defaults write NSGlobalDomain InitialKeyRepeat -int 15
        success "Set keyboard repeat rate for vim navigation"
        ;;
    esac

    success "Keyboard optimization for vim completed"
}

verify_neovim_installation() {
    info "Verifying Neovim installation..."

    if ! command_exists nvim; then
        error "Neovim not found in PATH"
        return 1
    fi

    local version
    version=$(nvim --version | head -1)
    success "Neovim installed: $version"

    # Check if LazyVim config exists
    if [[ -f "$NVIM_CONFIG_DIR/init.lua" ]]; then
        success "LazyVim configuration found"
    else
        warning "LazyVim configuration not found"
    fi

    # Test basic Neovim functionality
    if nvim --headless -c "q" 2>/dev/null; then
        success "Neovim basic functionality verified"
    else
        warning "Neovim may have configuration issues"
    fi

    success "Neovim installation verification completed"
}

show_neovim_next_steps() {
    print_header "Neovim + Keyboard Setup Complete"

    info "Next steps:"
    info "1. Run 'nvim' to start Neovim with LazyVim"
    info "2. LazyVim will automatically install plugins on first run"
    info "3. Use :LazyHealth to check plugin status"
    info "4. Use :Lazy to manage plugins"
    info "5. Check :help LazyVim for documentation"

    if [[ "${DOTFILES_OS}" == "macos" ]]; then
        info "6. Consider installing a Nerd Font for better icons"
    fi

    echo
    info "Keyboard optimizations:"
    info "  • Caps Lock → Escape (essential for vim workflow)"
    info "  • Optimized key repeat rate for vim navigation"
    info "  • You may need to restart your session for full effect"

    echo
    info "Key shortcuts:"
    info "  <leader> = Space key (thanks to Caps Lock → Escape!)"
    info "  <leader>ff = Find files"
    info "  <leader>fg = Live grep"
    info "  <leader>e = Toggle file explorer"
    info "  <leader>/ = Toggle comment"

    echo
    info "Python Development:"
    info "  <leader>pr = Run Python file"
    info "  <leader>pv = Select Python venv"
    info "  <leader>pd = Debug Python method"
    info "  <F5> = Start/Continue debugging"
    info "  <leader>db = Toggle breakpoint"

    echo
    info "DevOps Tools:"
    info "  <leader>ti = Terraform init"
    info "  <leader>tp = Terraform plan"
    info "  <leader>dk = Apply K8s manifest"
    info "  <leader>ys = Select YAML schema"
    info "  <leader>rr = Run REST request"

    echo
    info "Claude Code Integration:"
    info "  <leader>cc = Open Claude Code terminal (with vim mode)"
    info "  <leader>cs = Send selection to Claude Code (visual mode)"
    info "  <leader>cf = Send current file to Claude Code"
    info "  <leader>ce = Explain code with Claude (normal/visual mode)"
    info "  Note: Make sure 'claude' CLI is installed and authenticated"

    echo
    info "AI Auto-Completion (Cursor-like):"
    info "  <C-j> = Accept Copilot/AI suggestion"
    info "  <C-g> = Accept Codeium suggestion (when enabled)"
    info "  <C-l> = Accept word from Copilot"
    info "  <C-h> = Dismiss Copilot suggestion"
    info "  <C-n>/<C-p> = Cycle through AI suggestions"
    info "  <C-;>/<C-,> = Cycle Codeium completions (when enabled)"
    info "  Tab/S-Tab = Navigate snippets"
    info "  Note: Run ':Copilot setup' to authenticate Copilot"
    info "  Note: Run ':CodeiumEnable' to enable and authenticate Codeium (disabled by default)"

    echo
    success "Neovim with LazyVim, AI completion, Claude Code integration, and optimized keyboard layout is ready!"
}

main() {
    print_header "Neovim + LazyVim Environment Installer"

    info "Setting up Neovim with LazyVim for Python & DevOps development"
    info "Log file: $LOG_FILE"
    info "Backup directory: $BACKUP_DIR"

    # Install dependencies
    install_neovim_dependencies

    # Install Neovim if not already installed
    if ! command -v nvim >/dev/null 2>&1; then
        install_neovim_from_source
    else
        local version
        version=$(nvim --version | head -1)
        info "Neovim already installed: $version"
    fi

    # Setup LazyVim configuration
    setup_lazyvim
    install_language_servers
    configure_neovim_integration
    create_custom_lazyvim_config
    install_python_debugger

    # Keyboard optimization for vim workflow
    install_keyboard_dependencies
    setup_caps_to_escape
    optimize_keyboard_for_vim

    # Verify installation
    verify_neovim_installation

    show_neovim_next_steps

    success "Neovim + LazyVim environment setup completed!"
}

install_python_debugger() {
    info "Setting up Python debugging support..."

    # Install debugpy if not already installed
    if command_exists pip3; then
        pip3 install --user debugpy 2>/dev/null || true
    fi

    # Create debug configuration
    local dap_config_dir="$NVIM_CONFIG_DIR/lua/plugins"
    mkdir -p "$dap_config_dir"

    cat >"$dap_config_dir/dap-config.lua" <<'EOF'
return {
  {
    "mfussenegger/nvim-dap",
    keys = {
      { "<F5>", function() require("dap").continue() end, desc = "Debug: Start/Continue" },
      { "<F10>", function() require("dap").step_over() end, desc = "Debug: Step Over" },
      { "<F11>", function() require("dap").step_into() end, desc = "Debug: Step Into" },
      { "<F12>", function() require("dap").step_out() end, desc = "Debug: Step Out" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Debug: Toggle Breakpoint" },
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, desc = "Debug: Set Conditional Breakpoint" },
      { "<leader>dr", function() require("dap").repl.open() end, desc = "Debug: Open REPL" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "Debug: Run Last" },
      { "<leader>dh", function() require("dap.ui.widgets").hover() end, desc = "Debug: Hover" },
      { "<leader>dp", function() require("dap.ui.widgets").preview() end, desc = "Debug: Preview" },
      { "<leader>df", function() require("dap.ui.widgets").centered_float(require("dap.ui.widgets").frames) end, desc = "Debug: Frames" },
      { "<leader>ds", function() require("dap.ui.widgets").centered_float(require("dap.ui.widgets").scopes) end, desc = "Debug: Scopes" },
    },
  },
}
EOF

    success "Python debugging support configured"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

