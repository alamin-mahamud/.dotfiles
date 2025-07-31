# Development Productivity & Tooling Specifications

## Overview
Comprehensive development environment optimized for high-productivity engineering workflows, focusing on modern toolchains, automation, and seamless integration across local, remote, and cloud development scenarios.

## Modern Shell Environment

### Zsh Advanced Configuration
```yaml
zsh_setup:
  framework: "oh-my-zsh"
  theme: "powerlevel10k"
  
  plugins:
    core:
      - git
      - docker
      - kubectl
      - terraform
      - aws
      - gcloud
      - azure
    
    productivity:
      - zsh-autosuggestions
      - zsh-syntax-highlighting
      - zsh-completions
      - fzf-tab
      - z                     # Smart directory jumping
      - autojump             # Alternative to z
    
    development:
      - python
      - node
      - golang
      - rust
      - pip
      - pipenv
      - pyenv
      - nvm
    
    custom:
      - aliases-extended
      - docker-helpers
      - k8s-shortcuts
      - git-flow-completion

  custom_functions:
    development:
      - mkcd()              # Create and enter directory
      - extract()           # Universal archive extractor  
      - weather()           # Weather from command line
      - ports()             # Show listening ports
      - myip()              # Show external IP
    
    devops:
      - k8s-context()       # Quick context switching
      - aws-profile()       # AWS profile switching
      - docker-cleanup()    # Container/image cleanup
      - logs()              # Enhanced log viewing
```

### Terminal Multiplexer (tmux)
```yaml
tmux_configuration:
  version: "3.3+"
  
  keybindings:
    prefix: "C-a"           # Ctrl+a instead of Ctrl+b
    
    pane_management:
      - "| split-window -h"  # Vertical split
      - "- split-window -v"  # Horizontal split
      - "h select-pane -L"   # Navigate left
      - "j select-pane -D"   # Navigate down
      - "k select-pane -U"   # Navigate up
      - "l select-pane -R"   # Navigate right
    
    window_management:
      - "c new-window"
      - "n next-window"
      - "p previous-window"
      - "r source-file ~/.tmux.conf"
  
  plugins:
    tpm:                    # Tmux Plugin Manager
      - tmux-sensible
      - tmux-resurrect      # Session persistence
      - tmux-continuum      # Automatic save/restore
      - tmux-yank          # Copy to system clipboard
      - tmux-open          # Open highlighted text
      - tmux-battery-status # Battery indicator
      - tmux-cpu           # CPU usage indicator
  
  status_bar:
    position: "bottom"
    style: "minimal-informative"
    segments:
      left: "session_name window_index"
      right: "battery cpu_usage date_time"
    
    colors:
      background: "#1e1e1e"
      foreground: "#ffffff"
      accent: "#00d7ff"
```

### Modern CLI Tools
```yaml
cli_replacements:
  file_operations:
    - exa: "ls replacement with git integration"
    - bat: "cat replacement with syntax highlighting"
    - fd: "find replacement, faster and user-friendly"
    - ripgrep: "grep replacement, blazingly fast"
    - sd: "sed replacement with intuitive syntax"
    - dust: "du replacement with tree visualization"
    - procs: "ps replacement with color and tree view"
  
  navigation:
    - zoxide: "cd replacement with frecency algorithm"
    - broot: "tree replacement with navigation"
    - nnn: "file manager with plugins"
    - ranger: "vim-like file manager"
  
  networking:
    - httpie: "curl replacement for APIs"
    - dog: "dig replacement with JSON output"
    - gping: "ping replacement with graphs"
  
  development:
    - git-delta: "git diff with syntax highlighting"
    - lazygit: "terminal UI for git"
    - gh: "GitHub CLI"
    - glab: "GitLab CLI"
    - jq: "JSON processor"
    - yq: "YAML processor"
    - fx: "Interactive JSON viewer"
  
  system_monitoring:
    - htop: "top replacement"
    - iotop: "I/O monitoring"
    - nethogs: "network monitoring per process"
    - bandwhich: "network utilization by process"
    - bottom: "system monitor"
```

## Editor Configuration

### Neovim Setup
```yaml
neovim:
  version: "0.9+"
  configuration: "lua-based"
  
  plugin_manager: "lazy.nvim"
  
  core_plugins:
    lsp:
      - nvim-lspconfig       # LSP configurations
      - mason.nvim          # LSP installer
      - mason-lspconfig     # Bridge mason and lspconfig
      - null-ls.nvim        # Inject LSP diagnostics
    
    completion:
      - nvim-cmp            # Completion engine
      - cmp-nvim-lsp        # LSP source
      - cmp-buffer          # Buffer source
      - cmp-path            # Path source
      - cmp-cmdline         # Command line source
      - luasnip             # Snippet engine
      - cmp_luasnip         # Snippet source
    
    navigation:
      - telescope.nvim      # Fuzzy finder
      - nvim-tree.lua       # File explorer
      - harpoon             # File navigation
      - leap.nvim           # Motion plugin
    
    development:
      - nvim-treesitter     # Syntax highlighting
      - gitsigns.nvim       # Git integration
      - vim-fugitive        # Git commands
      - trouble.nvim        # Diagnostics panel
      - toggleterm.nvim     # Terminal integration
    
    productivity:
      - which-key.nvim      # Key binding helper
      - comment.nvim        # Smart commenting
      - surround.nvim       # Surround operations
      - auto-pairs          # Bracket completion
  
  language_servers:
    - pyright             # Python
    - tsserver            # TypeScript/JavaScript  
    - gopls               # Go
    - rust-analyzer       # Rust
    - lua-language-server # Lua
    - yaml-language-server # YAML
    - dockerfile-language-server # Docker
    - terraform-ls        # Terraform
    - helm-ls             # Helm
  
  custom_keymaps:
    leader: "<space>"
    
    file_operations:
      - "<leader>ff :Telescope find_files"
      - "<leader>fg :Telescope live_grep"
      - "<leader>fb :Telescope buffers"
      - "<leader>fh :Telescope help_tags"
    
    git_operations:
      - "<leader>gs :Git status"
      - "<leader>gc :Git commit"
      - "<leader>gp :Git push"
      - "<leader>gl :Git log"
    
    development:
      - "<leader>e :NvimTreeToggle"
      - "<leader>t :ToggleTerm"
      - "<leader>d :TroubleToggle"
```

### VS Code Configuration
```yaml
vscode:
  profile: "development-optimized"
  
  essential_extensions:
    general:
      - ms-vscode.vscode-json
      - ms-vscode.vscode-yaml
      - ms-vscode.vscode-markdown
      - ms-vscode.vscode-docker
      - ms-vscode.remote-ssh
      - ms-vscode.remote-containers
    
    development:
      - ms-python.python
      - ms-python.pylint
      - ms-python.black-formatter
      - bradlc.vscode-tailwindcss
      - esbenp.prettier-vscode
      - ms-vscode.vscode-typescript-next
    
    devops:
      - hashicorp.terraform
      - ms-kubernetes-tools.vscode-kubernetes-tools
      - ms-azuretools.vscode-docker
      - amazonwebservices.aws-toolkit-vscode
      - googlecloudtools.cloudcode
    
    productivity:
      - vscodevim.vim
      - ms-vscode.vscode-github-copilot
      - ms-vscode.vscode-github-copilot-chat
      - gitlens.gitlens
      - ms-vscode.vscode-todo-highlight
  
  settings:
    editor:
      fontSize: 14
      fontFamily: "'FiraCode Nerd Font Mono', 'JetBrains Mono', monospace"
      fontLigatures: true
      tabSize: 4
      insertSpaces: true
      wordWrap: "on"
      minimap.enabled: false
      rulers: [80, 120]
    
    workbench:
      colorTheme: "One Dark Pro"
      iconTheme: "material-icon-theme"
      startupEditor: "none"
    
    terminal:
      integrated.shell.linux: "/usr/bin/zsh"
      integrated.fontSize: 13
      integrated.fontFamily: "'FiraCode Nerd Font Mono'"
```

## Git Workflow Enhancement

### Advanced Git Configuration
```yaml
git_config:
  user:
    name: "{{ git_user_name }}"
    email: "{{ git_user_email }}"
    signingkey: "{{ git_signing_key }}"
  
  core:
    editor: "nvim"
    pager: "delta"
    autocrlf: false
    filemode: true
    ignorecase: false
  
  init:
    defaultBranch: "main"
  
  pull:
    rebase: true
  
  push:
    default: "current"
    autoSetupRemote: true
  
  fetch:
    prune: true
  
  diff:
    tool: "delta"
    colorMoved: "default"
  
  merge:
    tool: "nvim"
    conflictstyle: "diff3"
  
  rerere:
    enabled: true
  
  alias:
    # Status and info
    st: "status -sb"
    lg: "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
    
    # Commit operations
    cm: "commit -m"
    ca: "commit --amend"
    can: "commit --amend --no-edit"
    
    # Branch operations
    co: "checkout"
    cb: "checkout -b"
    br: "branch"
    brd: "branch -d"
    brD: "branch -D"
    
    # Remote operations
    ps: "push"
    psu: "push -u origin HEAD"
    pl: "pull"
    pf: "push --force-with-lease"
    
    # Diff operations
    df: "diff"
    dfc: "diff --cached"
    
    # Stash operations
    sl: "stash list"
    sa: "stash apply"
    ss: "stash save"
    sp: "stash pop"
    
    # Reset operations
    unstage: "reset HEAD --"
    undo: "reset --soft HEAD~1"
    
    # Utilities
    aliases: "!git config -l | grep alias | cut -c7-"
    ignore: "!gi() { curl -sL https://www.toptal.com/developers/gitignore/api/$@ ;}; gi"
```

### Git Flow & Workflow Tools
```yaml
git_workflow:
  git_flow:
    installation: "git-flow-avh"
    branch_prefixes:
      feature: "feature/"
      bugfix: "bugfix/"
      release: "release/"
      hotfix: "hotfix/"
      support: "support/"
      versiontag: "v"
  
  conventional_commits:
    types:
      - feat      # New feature
      - fix       # Bug fix
      - docs      # Documentation changes
      - style     # Code style changes
      - refactor  # Code refactoring
      - perf      # Performance improvements
      - test      # Test additions/modifications
      - chore     # Build process or auxiliary tool changes
      - ci        # CI configuration changes
      - build     # Build system changes
    
    scopes:
      - api
      - ui
      - core
      - config
      - deps
      - release
  
  hooks:
    pre_commit:
      - black                 # Python formatting
      - isort                 # Import sorting
      - flake8               # Python linting
      - prettier             # JavaScript/TypeScript formatting
      - eslint               # JavaScript/TypeScript linting
      - terraform-fmt        # Terraform formatting
      - terraform-validate   # Terraform validation
      - detect-secrets       # Secret detection
      - trailing-whitespace  # Remove trailing whitespace
      - end-of-file-fixer    # Ensure files end with newline
    
    commit_msg:
      - conventional-commit-checker
      - commitizen
    
    pre_push:
      - security-scan
      - license-check
      - docker-build-test
```

## Development Containers & Environments

### Docker Development
```yaml
docker_development:
  dev_containers:
    base_images:
      - python_dev:
          base: "python:3.11-slim"
          tools: ["poetry", "pytest", "black", "mypy"]
          
      - node_dev:
          base: "node:18-alpine"
          tools: ["npm", "yarn", "jest", "eslint", "prettier"]
          
      - go_dev:
          base: "golang:1.21-alpine"
          tools: ["golangci-lint", "air", "delve"]
          
      - rust_dev:
          base: "rust:1.72-slim"
          tools: ["cargo-watch", "clippy", "rustfmt"]
  
  compose_templates:
    full_stack:
      services:
        - app              # Application container
        - database         # PostgreSQL/MySQL
        - redis            # Cache layer
        - nginx            # Reverse proxy
        - monitoring       # Prometheus/Grafana
    
    microservices:
      services:
        - api_gateway
        - user_service
        - order_service
        - payment_service
        - message_queue
        - service_mesh
  
  development_workflow:
    - hot_reloading
    - volume_mounting
    - port_forwarding
    - environment_variables
    - secrets_management
```

### Remote Development
```yaml
remote_development:
  ssh_config:
    optimizations:
      - ControlMaster: "auto"
      - ControlPath: "~/.ssh/control-%r@%h:%p"
      - ControlPersist: "10m"
      - ServerAliveInterval: 30
      - ServerAliveCountMax: 3
      - TCPKeepAlive: "yes"
    
    host_templates:
      development_server:
        hostname: "dev.example.com"
        user: "developer"
        port: 22
        identityfile: "~/.ssh/dev_server_key"
        forwardagent: "yes"
        remotetunnel: "9090 localhost:9090"
  
  vscode_remote:
    extensions:
      - ms-vscode-remote.remote-ssh
      - ms-vscode-remote.remote-containers
      - ms-vscode-remote.remote-wsl
    
    settings:
      remote.SSH.remotePlatform:
        "dev.example.com": "linux"
      remote.SSH.defaultExtensions:
        - "ms-python.python"
        - "ms-vscode.vscode-json"
  
  tmux_remote:
    session_management:
      - named_sessions
      - session_persistence
      - automatic_reconnection
      - shared_sessions
```

## Database & API Development

### Database Tools
```yaml
database_tooling:
  clients:
    postgresql:
      - psql                # Command line client
      - pgcli               # Enhanced CLI with autocomplete
      - pg_dump             # Backup utility
      - pg_restore          # Restore utility
    
    mysql:
      - mysql               # Command line client
      - mycli               # Enhanced CLI
      - mysqldump           # Backup utility
    
    redis:
      - redis-cli           # Command line client
      - redis-commander     # Web interface
    
    mongodb:
      - mongosh             # Modern shell
      - mongo-express       # Web interface
  
  gui_clients:
    - dbeaver             # Universal database tool
    - pgadmin             # PostgreSQL administration
    - mysql-workbench     # MySQL GUI
    - robo3t              # MongoDB GUI
    - redis-desktop-manager # Redis GUI
  
  migration_tools:
    - flyway              # Database migrations
    - liquibase           # Database version control
    - alembic             # SQLAlchemy migrations
    - migrate             # Go migrations
```

### API Development & Testing
```yaml
api_tooling:
  http_clients:
    - httpie              # Command line HTTP client
    - curl                # Traditional HTTP client
    - postman             # GUI API client
    - insomnia            # Alternative GUI client
    - hurl                # HTTP runner for testing
  
  api_documentation:
    - swagger-ui          # OpenAPI documentation
    - redoc               # Alternative OpenAPI renderer
    - apispec             # OpenAPI spec generation
    - fastapi             # Python framework with auto-docs
  
  testing_frameworks:
    - pytest              # Python testing
    - jest                # JavaScript testing
    - newman              # Postman collection runner
    - dredd               # API blueprint testing
    - tavern              # YAML-based API testing
  
  mocking_tools:
    - wiremock            # HTTP service simulator
    - mockserver          # Mock server for testing
    - json-server         # Quick REST API mock
    - prism               # OpenAPI mock server
```

## Build & Automation Tools

### Task Runners & Build Tools
```yaml
automation:
  task_runners:
    - make                # Traditional make
    - just                # Modern command runner
    - task                # Go-based task runner
    - invoke              # Python task runner
    - npm_scripts         # Node.js scripts
  
  build_tools:
    python:
      - poetry            # Dependency management
      - pipenv            # Virtual environments
      - setuptools        # Package building
      - wheel             # Binary package format
    
    javascript:
      - webpack           # Module bundler
      - vite              # Fast build tool
      - rollup            # Module bundler
      - parcel            # Zero-config bundler
    
    go:
      - go_build          # Native build tool
      - goreleaser        # Release automation
      - mage              # Make alternative
    
    rust:
      - cargo             # Native build tool
      - cross             # Cross compilation
  
  ci_cd_local:
    - act                 # Run GitHub Actions locally
    - gitlab-runner       # GitLab CI local runner
    - drone-cli           # Drone CLI
    - tekton-cli          # Tekton pipelines
```

### Package Managers
```yaml
package_management:
  system_packages:
    ubuntu:
      - apt               # Default package manager
      - snap              # Universal packages
      - flatpak           # Alternative universal packages
    
    macos:
      - homebrew          # Package manager for macOS
      - macports          # Alternative package manager
  
  language_packages:
    - pip               # Python packages
    - npm               # Node.js packages  
    - yarn              # Alternative Node.js manager
    - pnpm              # Fast Node.js package manager
    - cargo             # Rust packages
    - go_mod            # Go modules
    - gem               # Ruby gems
    - composer          # PHP packages
  
  container_registries:
    - docker_hub        # Public container registry
    - ghcr              # GitHub Container Registry
    - ecr               # AWS Elastic Container Registry
    - gcr               # Google Container Registry
    - acr               # Azure Container Registry
```

## Productivity Profiles

### Minimal Developer Profile
```bash
# Essential tools only
minimal_dev:
  - zsh + basic plugins
  - tmux + essential plugins
  - neovim + LSP
  - git + delta
  - docker
  - basic CLI tools (bat, exa, ripgrep)
```

### Full Stack Developer Profile
```bash
# Complete development environment
fullstack_dev:
  - advanced_zsh_setup
  - tmux_with_all_plugins
  - neovim_full_config
  - vscode_with_extensions
  - database_clients
  - api_testing_tools
  - container_development
```

### DevOps Engineer Profile
```bash
# Infrastructure-focused tools
devops_engineer:
  - cloud_cli_tools
  - kubernetes_tools
  - terraform_tools
  - monitoring_clients
  - automation_scripts
  - security_scanners
```

### Remote Developer Profile
```bash
# Optimized for remote work
remote_developer:
  - ssh_optimizations
  - tmux_session_management
  - vscode_remote_development
  - vpn_configurations
  - bandwidth_optimized_tools
```