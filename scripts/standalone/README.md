# Standalone Installation Scripts

This directory contains **completely self-contained, idempotent installation scripts** designed for Ubuntu servers and compatible Linux distributions. Each script can be downloaded and executed independently without any dependencies on the dotfiles repository structure.

## 🎯 Design Principles

- **Zero Dependencies**: No external files or repository structure required
- **Idempotent**: Safe to run multiple times without conflicts
- **Self-Contained**: All utility functions embedded inline
- **Server-Optimized**: Designed for Ubuntu servers with minimal requirements
- **Comprehensive Logging**: Detailed logs and backup functionality
- **Graceful Failures**: Robust error handling and recovery

## 📦 Available Scripts

### 🐚 Shell Environment (`shell-env-standalone.sh`)
Complete shell environment with Zsh, Oh My Zsh, Powerlevel10k, Tmux, and modern CLI tools.

**Features:**
- Zsh with Oh My Zsh framework
- Powerlevel10k theme with instant prompt
- Essential plugins: autosuggestions, syntax-highlighting, completions
- Tmux with plugin manager and Catppuccin theme
- Modern CLI tools: ripgrep, fd, bat, eza, fzf, jq
- Comprehensive aliases and functions

**One-liner installation:**
```bash
curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/standalone/shell-env-standalone.sh | bash
```

**Options:**
- `--dry-run`: Preview changes without installing
- `--no-backup`: Skip configuration backups
- `--force`: Override existing installations
- `--debug`: Enable detailed debug output

### 🐍 Python Environment (`python-env-standalone.sh`)
Complete Python development environment with pyenv, multiple Python versions, and essential tools.

**Features:**
- pyenv for Python version management
- Multiple Python versions (3.11, 3.12 by default)
- pipx for isolated global package installation
- poetry for modern dependency management
- Essential tools: black, isort, flake8, mypy, pytest, ruff

**One-liner installation:**
```bash
curl -fsSL https://raw.githubusercontent.com/alamin-mahamud/.dotfiles/master/scripts/standalone/python-env-standalone.sh | bash
```

**Options:**
- `--python-versions "3.10,3.11,3.12"`: Specify Python versions
- `--default-version "3.11"`: Set global default Python version
- `--dry-run`: Preview installation
- `--no-backup`: Skip backups

**Custom installation examples:**
```bash
# Install specific Python versions
curl -fsSL <URL> | bash -s -- --python-versions "3.10,3.11,3.12" --default-version "3.11"

# Preview what would be installed
curl -fsSL <URL> | bash -s -- --dry-run
```

## 🚀 Quick Start

### Simple Installation
Download and run any script with a single command:
```bash
curl -fsSL <SCRIPT_URL> | bash
```

### Installation with Options
Pass options to scripts using the `-s --` pattern:
```bash
curl -fsSL <SCRIPT_URL> | bash -s -- --dry-run --debug
```

### Local Installation
Download, inspect, and run locally:
```bash
# Download the script
curl -fsSL <SCRIPT_URL> -o script.sh

# Make executable and review
chmod +x script.sh
less script.sh

# Run with options
./script.sh --dry-run
./script.sh --help
```

## 🎛 Common Options

All standalone scripts support these common options:

| Option | Description |
|--------|-------------|
| `--help`, `-h` | Show detailed help information |
| `--version`, `-v` | Display script version |
| `--dry-run` | Preview changes without making modifications |
| `--no-backup` | Skip backing up existing configuration files |
| `--force` | Override existing installations |
| `--debug` | Enable detailed debug output and logging |

## 📁 File Locations

### Logs and Backups
- **Installation logs**: `/tmp/<script>-install-YYYYMMDD-HHMMSS.log`
- **Configuration backups**: `/tmp/<script>-backup-YYYYMMDD-HHMMSS/`
- **Temporary markers**: `/tmp/.<script>-*` (for avoiding duplicate operations)

### Installed Components

#### Shell Environment
- **Oh My Zsh**: `~/.oh-my-zsh/`
- **Zsh plugins**: `~/.oh-my-zsh/custom/plugins/`
- **Powerlevel10k**: `~/.oh-my-zsh/custom/themes/powerlevel10k/`
- **Configuration**: `~/.zshrc`, `~/.p10k.zsh`
- **Tmux plugins**: `~/.tmux/plugins/`
- **Tmux config**: `~/.tmux.conf`
- **FZF**: `~/.fzf/`

#### Python Environment
- **pyenv**: `~/.pyenv/`
- **pipx apps**: `~/.local/bin/` and `~/.local/share/pipx/`
- **Configuration**: `~/.python_env` (standalone config file)
- **Shell integration**: Added to `~/.zshrc`, `~/.bashrc`, etc.

## 🔧 Customization

### Environment Variables
Scripts respect these environment variables:
- `DEBUG=1`: Enable debug output
- `FORCE=1`: Force installation even if components exist
- `NO_BACKUP=1`: Skip configuration backups

### Manual Customization
After installation, you can customize configurations:

**Shell Environment:**
- Edit `~/.zshrc` for shell customization
- Run `p10k configure` to customize Powerlevel10k theme
- Edit `~/.tmux.conf` for Tmux settings

**Python Environment:**
- Use `pyenv install <version>` to add Python versions
- Use `pyenv global <version>` to change default version
- Use `pipx install <tool>` to add development tools

## 🐛 Troubleshooting

### Common Issues

**Permission Errors:**
```bash
# If you see permission errors, ensure you have sudo access:
sudo -v

# Some installations require adding user to groups:
# Log out and back in after installation if needed
```

**Network Issues:**
```bash
# Test connectivity before installation:
curl -I https://www.google.com

# Use local package mirrors if available
# Scripts will continue with warnings if some network operations fail
```

**Existing Installation Conflicts:**
```bash
# Use --force to override existing installations:
curl -fsSL <URL> | bash -s -- --force

# Or preview with --dry-run first:
curl -fsSL <URL> | bash -s -- --dry-run
```

### Recovery

**Restore from Backup:**
```bash
# Backups are stored in /tmp/
ls /tmp/*-backup-*/

# Manually restore if needed:
cp /tmp/script-backup-*/filename ~/original-location
```

**Clean Installation:**
```bash
# Remove existing installations and reinstall:
rm -rf ~/.oh-my-zsh ~/.pyenv ~/.tmux
./script.sh --force
```

### Debug Mode
Enable detailed debugging for troubleshooting:
```bash
curl -fsSL <URL> | bash -s -- --debug
```

## 🔒 Security Considerations

### Script Verification
Always verify scripts before piping to bash:
```bash
# Review the script first:
curl -fsSL <URL> | less

# Or download and inspect:
curl -fsSL <URL> -o script.sh
less script.sh
chmod +x script.sh
./script.sh
```

### Permissions
Scripts will:
- Request sudo only when necessary (package installation)
- Never require root user execution
- Create backups before modifying configurations
- Use appropriate file permissions

## 📊 Compatibility Matrix

| OS/Version | Shell Env | Python Env | Status |
|------------|-----------|------------|---------|
| Ubuntu 24.04 LTS | ✅ | ✅ | Fully Tested |
| Ubuntu 22.04 LTS | ✅ | ✅ | Fully Tested |
| Ubuntu 20.04 LTS | ✅ | ✅ | Tested |
| Debian 12 | ✅ | ✅ | Compatible |
| Debian 11 | ✅ | ✅ | Compatible |
| Fedora 38+ | ⚠️ | ⚠️ | Partially Tested |
| CentOS/RHEL 8+ | ⚠️ | ⚠️ | Partially Tested |

**Legend:**
- ✅ Fully tested and supported
- ⚠️ Should work but may require manual intervention
- ❌ Not supported

## 🆚 Differences from Component Installers

| Aspect | Standalone Scripts | Component Installers |
|--------|-------------------|----------------------|
| **Dependencies** | None - completely self-contained | Require `scripts/lib/` files |
| **Repository** | Can run from any URL | Must be run from dotfiles repo |
| **Size** | Larger (embedded utilities) | Smaller (shared libraries) |
| **Maintenance** | Independent updates | Shared library updates |
| **Portability** | Maximum - single file | Repository dependent |
| **Customization** | Command-line flags | Environment variables + flags |

## 🤝 Contributing

### Adding New Standalone Scripts

1. **Copy Template**: Use `shell-env-standalone.sh` as a template
2. **Embed Utilities**: Include all required utility functions inline
3. **Add Options**: Support standard options (`--help`, `--version`, `--dry-run`, etc.)
4. **Test Thoroughly**: Ensure idempotent operation and error handling
5. **Document**: Update this README with the new script

### Testing Checklist

- [ ] Script runs successfully on fresh Ubuntu 22.04/24.04
- [ ] `--dry-run` shows correct planned actions
- [ ] Script is idempotent (can run multiple times safely)
- [ ] `--help` shows comprehensive usage information
- [ ] Error handling works for common failure scenarios
- [ ] Backups are created correctly
- [ ] No external file dependencies

## 📞 Support

### Getting Help
- **Documentation**: This README and `--help` output
- **Logs**: Check installation logs in `/tmp/`
- **Backups**: Restore from automatic backups if needed
- **Issues**: Report problems with detailed logs and environment info

### Reporting Issues
Include:
1. Operating system and version
2. Script name and version
3. Command used to run script
4. Full error message
5. Installation log from `/tmp/`

---

**Version**: 1.0.0  
**Updated**: December 2024  
**Compatibility**: Ubuntu 20.04+ and compatible Linux distributions
