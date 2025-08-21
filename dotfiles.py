#!/usr/bin/env python3
"""
Dotfiles installer - Pythonic implementation.

The Zen of Python principles applied:
- Beautiful is better than ugly
- Explicit is better than implicit
- Simple is better than complex
- Complex is better than complicated
- Flat is better than nested
- Sparse is better than dense
- Readability counts
- Special cases aren't special enough to break the rules
- Errors should never pass silently
- There should be one-- and preferably only one --obvious way to do it
- If the implementation is hard to explain, it's a bad idea
"""

import os
import sys
import json
import shutil
import platform
import subprocess
import tempfile
import logging
from pathlib import Path
from typing import Optional, List, Dict, Any, Union
from datetime import datetime
from dataclasses import dataclass, field
from enum import Enum, auto
import urllib.request
import urllib.error


class OS(Enum):
    """Operating system types."""
    LINUX = auto()
    MACOS = auto()
    UNKNOWN = auto()


class Environment(Enum):
    """Environment types."""
    DESKTOP = auto()
    SERVER = auto()
    WSL = auto()


@dataclass
class SystemInfo:
    """System information container."""
    os: str = field(init=False)
    distro: str = field(init=False)
    arch: str = field(init=False)
    is_wsl: bool = field(init=False)
    is_desktop: bool = field(init=False)
    display_server: str = field(init=False)
    
    def __post_init__(self):
        """Initialize system information."""
        self.os = self._detect_os()
        self.distro = self._detect_distro()
        self.arch = self._detect_arch()
        self.is_wsl = self._detect_wsl()
        self.is_desktop = self._detect_desktop()
        self.display_server = self._detect_display_server()
    
    def _detect_os(self) -> str:
        """Detect operating system."""
        system = platform.system().lower()
        return 'macos' if system == 'darwin' else system
    
    def _detect_distro(self) -> str:
        """Detect Linux distribution."""
        if self.os != 'linux':
            return 'none'
        
        try:
            with open('/etc/os-release') as f:
                for line in f:
                    if line.startswith('ID='):
                        return line.split('=')[1].strip().strip('"').lower()
        except FileNotFoundError:
            pass
        
        return 'unknown'
    
    def _detect_arch(self) -> str:
        """Detect system architecture."""
        machine = platform.machine()
        arch_map = {
            'x86_64': 'amd64',
            'aarch64': 'arm64',
            'arm64': 'arm64',
            'armv7l': 'armv7'
        }
        return arch_map.get(machine, machine)
    
    def _detect_wsl(self) -> bool:
        """Detect if running in WSL."""
        return 'microsoft' in platform.release().lower()
    
    def _detect_desktop(self) -> bool:
        """Detect if desktop environment is available."""
        return bool(os.environ.get('DISPLAY') or os.environ.get('WAYLAND_DISPLAY'))
    
    def _detect_display_server(self) -> str:
        """Detect display server type."""
        if not self.is_desktop:
            return 'none'
        
        if os.environ.get('WAYLAND_DISPLAY'):
            return 'wayland'
        elif os.environ.get('DISPLAY'):
            return 'x11'
        
        return 'unknown'


class Logger:
    """Simple logging with colors."""
    
    COLORS = {
        'RED': '\033[0;31m',
        'GREEN': '\033[0;32m',
        'YELLOW': '\033[1;33m',
        'BLUE': '\033[0;34m',
        'PURPLE': '\033[0;35m',
        'CYAN': '\033[0;36m',
        'WHITE': '\033[1;37m',
        'NC': '\033[0m'
    }
    
    def __init__(self, log_file: Optional[str] = None, debug: bool = False):
        """Initialize logger."""
        self.debug_mode = debug
        if log_file:
            self.log_file = Path(log_file)
        else:
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            self.log_file = Path(f'/tmp/dotfiles_{timestamp}.log')
        
        self.log_file.parent.mkdir(parents=True, exist_ok=True)
    
    def _log(self, message: str, color: str = 'NC', file=sys.stdout):
        """Log message with color."""
        colored_msg = f"{self.COLORS[color]}{message}{self.COLORS['NC']}"
        print(colored_msg, file=file)
        
        with open(self.log_file, 'a') as f:
            f.write(f"{datetime.now().isoformat()} - {message}\n")
    
    def info(self, message: str):
        """Log info message."""
        self._log(f"→ {message}", 'CYAN')
    
    def success(self, message: str):
        """Log success message."""
        self._log(f"✓ {message}", 'GREEN')
    
    def warning(self, message: str):
        """Log warning message."""
        self._log(f"⚠ {message}", 'YELLOW')
    
    def error(self, message: str, exit: bool = True):
        """Log error message."""
        self._log(f"✗ {message}", 'RED', file=sys.stderr)
        if exit:
            sys.exit(1)
    
    def debug(self, message: str):
        """Log debug message."""
        if self.debug_mode:
            self._log(f"DEBUG: {message}", 'PURPLE')
    
    def header(self, message: str):
        """Log header message."""
        self._log(message, 'WHITE')
        self._log('=' * len(message), 'WHITE')


class Config:
    """Configuration management."""
    
    DEFAULT_CONFIG = {
        'dotfiles_root': Path.home() / 'Work' / '.dotfiles',
        'backup_dir': Path.home() / '.dotfiles-backup',
        'shell': {
            'default': 'zsh',
            'theme': 'powerlevel10k'
        },
        'tools': [
            'ripgrep', 'fd', 'bat', 'eza', 'fzf',
            'tmux', 'neovim', 'htop', 'jq', 'tldr'
        ],
        'fonts': [
            'FiraCode', 'JetBrainsMono', 'Iosevka'
        ]
    }
    
    def __init__(self, config_file: Optional[str] = None):
        """Initialize configuration."""
        self.config = self.DEFAULT_CONFIG.copy()
        
        if config_file and Path(config_file).exists():
            with open(config_file) as f:
                user_config = json.load(f)
                self._merge_config(self.config, user_config)
    
    def _merge_config(self, base: Dict, update: Dict):
        """Recursively merge configuration dictionaries."""
        for key, value in update.items():
            if key in base and isinstance(base[key], dict) and isinstance(value, dict):
                self._merge_config(base[key], value)
            else:
                base[key] = value
    
    def get(self, key: str, default: Any = None) -> Any:
        """Get configuration value using dot notation."""
        keys = key.split('.')
        value = self.config
        
        for k in keys:
            if isinstance(value, dict):
                value = value.get(k)
                if value is None:
                    return default
            else:
                return default
        
        return value


class PackageManager:
    """Package management abstraction."""
    
    MANAGERS = {
        'apt': {
            'install': ['sudo', 'apt', 'install', '-y'],
            'update': ['sudo', 'apt', 'update'],
            'search': ['apt', 'search']
        },
        'dnf': {
            'install': ['sudo', 'dnf', 'install', '-y'],
            'update': ['sudo', 'dnf', 'check-update'],
            'search': ['dnf', 'search']
        },
        'pacman': {
            'install': ['sudo', 'pacman', '-S', '--noconfirm'],
            'update': ['sudo', 'pacman', '-Sy'],
            'search': ['pacman', '-Ss']
        },
        'brew': {
            'install': ['brew', 'install'],
            'update': ['brew', 'update'],
            'search': ['brew', 'search']
        },
        'apk': {
            'install': ['sudo', 'apk', 'add'],
            'update': ['sudo', 'apk', 'update'],
            'search': ['apk', 'search']
        }
    }
    
    def __init__(self):
        """Initialize package manager."""
        self.manager = self._detect_manager()
        self.logger = Logger()
    
    def _detect_manager(self) -> Optional[str]:
        """Detect available package manager."""
        for manager in self.MANAGERS:
            if shutil.which(manager):
                return manager
        return None
    
    def update(self):
        """Update package lists."""
        if not self.manager:
            self.logger.warning("No package manager found")
            return
        
        self.logger.info(f"Updating package lists with {self.manager}")
        run_command(self.MANAGERS[self.manager]['update'])
    
    def install(self, packages: Union[str, List[str]]):
        """Install packages."""
        if not self.manager:
            self.logger.error("No package manager found")
            return
        
        if isinstance(packages, str):
            packages = [packages]
        
        if not packages:
            return
        
        self.logger.info(f"Installing {', '.join(packages)}")
        cmd = self.MANAGERS[self.manager]['install'] + packages
        run_command(cmd)


class FileManager:
    """File operations manager."""
    
    def __init__(self):
        """Initialize file manager."""
        self.logger = Logger()
    
    def backup(self, path: Union[str, Path]) -> Path:
        """Backup file or directory."""
        path = Path(path)
        if not path.exists():
            return path
        
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        backup_path = path.parent / f"{path.name}.backup.{timestamp}"
        
        if path.is_dir():
            shutil.copytree(path, backup_path)
        else:
            shutil.copy2(path, backup_path)
        
        self.logger.success(f"Backed up {path} to {backup_path}")
        return backup_path
    
    def symlink(self, source: Union[str, Path], target: Union[str, Path], backup: bool = True):
        """Create symlink."""
        source = Path(source).resolve()
        target = Path(target)
        
        if not source.exists():
            self.logger.error(f"Source {source} does not exist")
            return
        
        if target.exists() or target.is_symlink():
            if backup:
                self.backup(target)
            target.unlink()
        
        target.parent.mkdir(parents=True, exist_ok=True)
        target.symlink_to(source)
        self.logger.success(f"Created symlink {target} → {source}")
    
    def ensure_dir(self, path: Union[str, Path]) -> Path:
        """Ensure directory exists."""
        path = Path(path)
        path.mkdir(parents=True, exist_ok=True)
        return path


class ShellEnvironment:
    """Shell environment installer."""
    
    def __init__(self):
        """Initialize shell environment installer."""
        self.logger = Logger()
        self.pm = PackageManager()
        self.fm = FileManager()
        self.config = Config()
    
    def install_zsh(self):
        """Install and configure Zsh."""
        self.logger.info("Installing Zsh")
        
        if not command_exists('zsh'):
            self.pm.install('zsh')
        
        zsh_path = shutil.which('zsh')
        if not zsh_path:
            self.logger.error("Failed to find Zsh after installation")
            return
        
        # Add to /etc/shells if needed
        try:
            with open('/etc/shells', 'r') as f:
                if zsh_path not in f.read():
                    run_command(['sudo', 'tee', '-a', '/etc/shells'], input=zsh_path)
        except Exception as e:
            self.logger.warning(f"Could not update /etc/shells: {e}")
        
        # Set as default shell
        current_shell = os.environ.get('SHELL', '')
        if 'zsh' not in current_shell:
            try:
                run_command(['chsh', '-s', zsh_path])
                self.logger.success("Set Zsh as default shell")
            except Exception as e:
                self.logger.warning(f"Could not change shell: {e}")
    
    def install_oh_my_zsh(self):
        """Install Oh My Zsh framework."""
        omz_dir = Path.home() / '.oh-my-zsh'
        
        if omz_dir.exists():
            self.logger.info("Updating Oh My Zsh")
            run_command(['git', 'pull'], cwd=omz_dir)
        else:
            self.logger.info("Installing Oh My Zsh")
            repo_url = 'https://github.com/ohmyzsh/ohmyzsh.git'
            run_command(['git', 'clone', '--depth=1', repo_url, str(omz_dir)])
        
        self.logger.success("Oh My Zsh ready")
    
    def install_zsh_plugins(self):
        """Install Zsh plugins."""
        custom_dir = Path.home() / '.oh-my-zsh' / 'custom'
        plugins_dir = custom_dir / 'plugins'
        themes_dir = custom_dir / 'themes'
        
        plugins = [
            ('zsh-autosuggestions', 'https://github.com/zsh-users/zsh-autosuggestions'),
            ('zsh-syntax-highlighting', 'https://github.com/zsh-users/zsh-syntax-highlighting'),
            ('zsh-completions', 'https://github.com/zsh-users/zsh-completions'),
            ('fzf-tab', 'https://github.com/Aloxaf/fzf-tab')
        ]
        
        for name, url in plugins:
            plugin_dir = plugins_dir / name
            if plugin_dir.exists():
                self.logger.info(f"Updating {name}")
                run_command(['git', 'pull'], cwd=plugin_dir)
            else:
                self.logger.info(f"Installing {name}")
                run_command(['git', 'clone', '--depth=1', url, str(plugin_dir)])
        
        # Install Powerlevel10k theme
        p10k_dir = themes_dir / 'powerlevel10k'
        if p10k_dir.exists():
            self.logger.info("Updating Powerlevel10k")
            run_command(['git', 'pull'], cwd=p10k_dir)
        else:
            self.logger.info("Installing Powerlevel10k")
            p10k_url = 'https://github.com/romkatv/powerlevel10k.git'
            run_command(['git', 'clone', '--depth=1', p10k_url, str(p10k_dir)])
        
        self.logger.success("Zsh plugins installed")
    
    def install_tmux(self):
        """Install and configure Tmux."""
        self.logger.info("Installing Tmux")
        
        if not command_exists('tmux'):
            self.pm.install('tmux')
        
        # Install TPM (Tmux Plugin Manager)
        tpm_dir = Path.home() / '.tmux' / 'plugins' / 'tpm'
        if not tpm_dir.exists():
            self.logger.info("Installing TPM")
            tpm_url = 'https://github.com/tmux-plugins/tpm'
            run_command(['git', 'clone', '--depth=1', tpm_url, str(tpm_dir)])
        
        self.logger.success("Tmux configured")
    
    def install_cli_tools(self):
        """Install modern CLI tools."""
        tools = self.config.get('tools', [])
        
        # Map tool names to package names per OS/distro
        tool_map = {
            'eza': 'eza',  # eza is the modern replacement for exa
            'fd': 'fd-find' if self.pm.manager == 'apt' else 'fd'
        }
        
        packages = [tool_map.get(tool, tool) for tool in tools]
        
        self.logger.info("Installing CLI tools")
        self.pm.install(packages)
        self.logger.success("CLI tools installed")
    
    def setup_dotfiles(self):
        """Setup dotfile symlinks."""
        dotfiles_root = self.config.get('dotfiles_root')
        
        dotfiles = {
            dotfiles_root / 'zsh' / '.zshrc': Path.home() / '.zshrc',
            dotfiles_root / 'tmux' / '.tmux.conf': Path.home() / '.tmux.conf',
            dotfiles_root / 'git' / '.gitconfig': Path.home() / '.gitconfig'
        }
        
        for source, target in dotfiles.items():
            if source.exists():
                self.fm.symlink(source, target)
    
    def install(self):
        """Install complete shell environment."""
        self.install_zsh()
        self.install_oh_my_zsh()
        self.install_zsh_plugins()
        self.install_tmux()
        self.install_cli_tools()
        self.setup_dotfiles()


class PythonEnvironment:
    """Python development environment installer."""
    
    def __init__(self):
        """Initialize Python environment installer."""
        self.logger = Logger()
        self.pm = PackageManager()
    
    def install_pyenv(self):
        """Install pyenv for Python version management."""
        pyenv_root = Path.home() / '.pyenv'
        
        if pyenv_root.exists():
            self.logger.info("Updating pyenv")
            run_command(['git', 'pull'], cwd=pyenv_root)
        else:
            self.logger.info("Installing pyenv")
            pyenv_url = 'https://github.com/pyenv/pyenv.git'
            run_command(['git', 'clone', pyenv_url, str(pyenv_root)])
        
        # Install build dependencies
        self.logger.info("Installing Python build dependencies")
        deps = ['build-essential', 'libssl-dev', 'zlib1g-dev', 'libbz2-dev',
                'libreadline-dev', 'libsqlite3-dev', 'wget', 'curl', 'llvm',
                'libncurses5-dev', 'libncursesw5-dev', 'xz-utils', 'tk-dev',
                'libffi-dev', 'liblzma-dev', 'python3-openssl', 'git']
        
        if self.pm.manager == 'apt':
            self.pm.install(deps)
        
        self.logger.success("pyenv installed")
    
    def install_poetry(self):
        """Install Poetry for dependency management."""
        self.logger.info("Installing Poetry")
        
        # Check if poetry is already installed
        if command_exists('poetry'):
            self.logger.info("Poetry already installed")
            return
        
        try:
            # Try pipx installation first (more reliable)
            if command_exists('pipx'):
                run_command(['pipx', 'install', 'poetry'])
                self.logger.success("Poetry installed via pipx")
                return
            
            # Fallback to official installer with symlinks enabled
            installer_url = 'https://install.python-poetry.org'
            with tempfile.NamedTemporaryFile(suffix='.py', delete=False) as f:
                urllib.request.urlretrieve(installer_url, f.name)
                # Set environment variable to enable symlinks
                env = os.environ.copy()
                env['POETRY_VENV_SYMLINKS'] = '1'
                result = subprocess.run(['python3', f.name], env=env, capture_output=True, text=True)
                Path(f.name).unlink()
                if result.returncode != 0:
                    raise subprocess.CalledProcessError(result.returncode, ['python3', f.name])
                
        except subprocess.CalledProcessError as e:
            self.logger.warning(f"Poetry installation failed: {e}")
            self.logger.info("You can install Poetry manually later with: curl -sSL https://install.python-poetry.org | python3 -")
            return
        
        self.logger.success("Poetry installed")
    
    def install_pipx(self):
        """Install pipx for global Python applications."""
        self.logger.info("Installing pipx")
        
        if not command_exists('pipx'):
            run_command(['python3', '-m', 'pip', 'install', '--user', 'pipx'])
            run_command(['python3', '-m', 'pipx', 'ensurepath'])
        
        self.logger.success("pipx installed")
    
    def install(self):
        """Install complete Python environment."""
        self.install_pyenv()
        self.install_poetry()
        self.install_pipx()


class DesktopEnvironment:
    """Desktop environment setup."""
    
    def __init__(self):
        """Initialize desktop environment installer."""
        self.logger = Logger()
        self.pm = PackageManager()
        self.system = SystemInfo()
    
    def install_fonts(self):
        """Install Nerd Fonts."""
        fonts_dir = Path.home() / '.local' / 'share' / 'fonts'
        fonts_dir.mkdir(parents=True, exist_ok=True)
        
        fonts = ['FiraCode', 'JetBrainsMono', 'Iosevka']
        base_url = 'https://github.com/ryanoasis/nerd-fonts/releases/latest/download'
        
        for font in fonts:
            self.logger.info(f"Installing {font} Nerd Font")
            font_url = f"{base_url}/{font}.tar.xz"
            font_file = fonts_dir / f"{font}.tar.xz"
            
            try:
                urllib.request.urlretrieve(font_url, font_file)
                run_command(['tar', '-xf', str(font_file)], cwd=fonts_dir)
                font_file.unlink()
            except Exception as e:
                self.logger.warning(f"Failed to install {font}: {e}")
        
        # Update font cache
        run_command(['fc-cache', '-fv'])
        self.logger.success("Fonts installed")
    
    def setup_keyboard(self):
        """Setup keyboard (Caps Lock to Escape)."""
        self.logger.info("Setting up keyboard")
        
        if self.system.os == 'macos':
            # macOS: Use hidutil
            plist_content = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.capslock-escape</string>
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
</plist>'''
            plist_path = Path.home() / 'Library' / 'LaunchAgents' / 'com.user.capslock-escape.plist'
            plist_path.parent.mkdir(parents=True, exist_ok=True)
            plist_path.write_text(plist_content)
            run_command(['launchctl', 'load', str(plist_path)])
        
        elif self.system.os == 'linux':
            # Linux: Try different methods
            if self.system.display_server == 'x11':
                run_command(['setxkbmap', '-option', 'caps:escape'])
            elif command_exists('gsettings'):
                run_command(['gsettings', 'set', 'org.gnome.desktop.input-sources', 
                           'xkb-options', "['caps:escape']"])
        
        self.logger.success("Keyboard configured")
    
    def install(self):
        """Install desktop environment components."""
        self.install_fonts()
        self.setup_keyboard()


class DotfilesInstaller:
    """Main dotfiles installer."""
    
    def __init__(self):
        """Initialize installer."""
        self.logger = Logger()
        self.system = SystemInfo()
        self.config = Config()
        self.pm = PackageManager()
        self.fm = FileManager()
        
        self.shell_env = ShellEnvironment()
        self.python_env = PythonEnvironment()
        self.desktop_env = DesktopEnvironment()
    
    def check_prerequisites(self):
        """Check and install prerequisites."""
        self.logger.info("Checking prerequisites")
        
        required = ['git', 'curl']
        missing = [cmd for cmd in required if not command_exists(cmd)]
        
        if missing:
            self.logger.info(f"Installing missing prerequisites: {', '.join(missing)}")
            self.pm.update()
            self.pm.install(missing)
        
        if not check_internet():
            self.logger.error("Internet connection required")
        
        self.logger.success("Prerequisites satisfied")
    
    def setup_directories(self):
        """Setup directory structure."""
        self.logger.info("Setting up directories")
        
        dirs = [
            Path.home() / 'Work',
            Path.home() / '.config',
            Path.home() / '.local' / 'bin',
            Path.home() / '.local' / 'share' / 'fonts'
        ]
        
        for directory in dirs:
            self.fm.ensure_dir(directory)
        
        self.logger.success("Directories created")
    
    def clone_dotfiles(self):
        """Clone or update dotfiles repository."""
        dotfiles_root = self.config.get('dotfiles_root')
        
        if dotfiles_root.exists():
            self.logger.info("Checking dotfiles repository status")
            try:
                # Check if we're in a git repository
                run_command(['git', 'rev-parse', '--git-dir'], cwd=dotfiles_root, capture_output=True)
                
                # Check for uncommitted changes
                status_result = run_command(['git', 'status', '--porcelain'], cwd=dotfiles_root, capture_output=True)
                if status_result.stdout.strip():
                    self.logger.warning("Uncommitted changes detected in dotfiles repository")
                    self.logger.info("Stashing local changes...")
                    run_command(['git', 'stash', 'push', '-m', 'Auto-stash before pull'], cwd=dotfiles_root)
                    
                    # Pull latest changes
                    self.logger.info("Pulling latest changes")
                    run_command(['git', 'pull', '--rebase'], cwd=dotfiles_root)
                    
                    # Pop stash if we stashed anything
                    stash_list = run_command(['git', 'stash', 'list'], cwd=dotfiles_root, capture_output=True)
                    if 'Auto-stash before pull' in stash_list.stdout:
                        self.logger.info("Reapplying stashed changes")
                        try:
                            run_command(['git', 'stash', 'pop'], cwd=dotfiles_root)
                        except subprocess.CalledProcessError:
                            self.logger.warning("Conflicts detected when applying stash. Please resolve manually.")
                            self.logger.info("Run 'git stash pop' in the dotfiles directory to apply changes")
                else:
                    # No local changes, safe to pull
                    self.logger.info("Updating dotfiles repository")
                    run_command(['git', 'pull'], cwd=dotfiles_root)
            except subprocess.CalledProcessError as e:
                self.logger.error(f"Failed to update repository: {e}")
                self.logger.info("Continuing with existing dotfiles...")
        else:
            self.logger.info("Cloning dotfiles repository")
            repo_url = 'https://github.com/alamin-mahamud/.dotfiles.git'
            try:
                run_command(['git', 'clone', repo_url, str(dotfiles_root)])
            except subprocess.CalledProcessError as e:
                self.logger.error(f"Failed to clone repository: {e}")
                raise
        
        self.logger.success("Dotfiles repository ready")
    
    def install_system_packages(self):
        """Install essential system packages."""
        self.logger.info("Installing system packages")
        
        packages = {
            'apt': ['build-essential', 'software-properties-common', 'apt-transport-https',
                   'ca-certificates', 'gnupg', 'lsb-release'],
            'dnf': ['@development-tools', 'dnf-plugins-core'],
            'pacman': ['base-devel'],
            'brew': ['coreutils', 'findutils', 'gnu-tar', 'gnu-sed', 'gawk', 'gnutls', 
                    'gnu-indent', 'gnu-getopt', 'grep']
        }
        
        if self.pm.manager in packages:
            self.pm.install(packages[self.pm.manager])
        
        self.logger.success("System packages installed")
    
    def run_full_install(self):
        """Run full installation."""
        self.check_prerequisites()
        self.setup_directories()
        self.clone_dotfiles()
        self.install_system_packages()
        self.shell_env.install()
        self.python_env.install()
        
        if self.system.is_desktop:
            self.desktop_env.install()
        
        self.show_completion()
    
    def run_shell_only(self):
        """Install shell environment only."""
        self.check_prerequisites()
        self.setup_directories()
        self.clone_dotfiles()
        self.shell_env.install()
        self.show_completion()
    
    def run_python_only(self):
        """Install Python environment only."""
        self.check_prerequisites()
        self.python_env.install()
        self.show_completion()
    
    def show_menu(self):
        """Show interactive menu."""
        self.logger.header("Dotfiles Installer")
        self.logger.info(f"OS: {self.system.os}")
        self.logger.info(f"Distribution: {self.system.distro}")
        self.logger.info(f"Architecture: {self.system.arch}")
        self.logger.info(f"Environment: {'Desktop' if self.system.is_desktop else 'Server'}")
        
        print("\nOptions:")
        print("1) Full installation")
        print("2) Shell environment only")
        print("3) Python environment only")
        print("4) Desktop features only")
        print("q) Quit")
        
        return input("\nChoice: ").strip()
    
    def run_interactive(self):
        """Run interactive installation."""
        choice = self.show_menu()
        
        actions = {
            '1': self.run_full_install,
            '2': self.run_shell_only,
            '3': self.run_python_only,
            '4': self.desktop_env.install
        }
        
        if choice in actions:
            actions[choice]()
        elif choice.lower() == 'q':
            self.logger.info("Installation cancelled")
            sys.exit(0)
        else:
            self.logger.warning("Invalid choice")
            self.run_interactive()
    
    def show_completion(self):
        """Show completion message."""
        self.logger.header("Installation Complete!")
        self.logger.info("Next steps:")
        self.logger.info("1. Restart terminal or run: exec zsh")
        self.logger.info("2. Configure Powerlevel10k: p10k configure")
        self.logger.info("3. Install tmux plugins: <Ctrl-a> + I")
        self.logger.info(f"\nLog file: {self.logger.log_file}")


def command_exists(command: str) -> bool:
    """Check if command exists."""
    return shutil.which(command) is not None


def run_command(cmd: List[str], check: bool = True, capture_output: bool = True, 
                text: bool = True, input: str = None, cwd: Path = None) -> subprocess.CompletedProcess:
    """Run shell command with detailed error reporting."""
    try:
        result = subprocess.run(cmd, check=check, capture_output=capture_output, 
                              text=text, input=input, cwd=cwd)
        return result
    except subprocess.CalledProcessError as e:
        error_msg = f"Command failed: {' '.join(cmd)}"
        if cwd:
            error_msg += f"\nWorking directory: {cwd}"
        error_msg += f"\nReturn code: {e.returncode}"
        if e.stdout:
            error_msg += f"\nStdout: {e.stdout}"
        if e.stderr:
            error_msg += f"\nStderr: {e.stderr}"
        Logger().error(error_msg)
        raise
    except FileNotFoundError as e:
        Logger().error(f"Command not found: {cmd[0]}\nFull command: {' '.join(cmd)}")
        raise
    except Exception as e:
        Logger().error(f"Unexpected error running command: {' '.join(cmd)}\nError: {e}")
        raise


def ask_yes_no(prompt: str, default: bool = True) -> bool:
    """Ask yes/no question."""
    suffix = " [Y/n] " if default else " [y/N] "
    response = input(prompt + suffix).strip().lower()
    
    if not response:
        return default
    
    return response[0] == 'y'


def safe_git_pull(repo_path: Path, repo_name: str = "repository") -> bool:
    """Safely pull git repository, handling uncommitted changes."""
    logger = Logger()
    try:
        # Check if it's a git repository
        run_command(['git', 'rev-parse', '--git-dir'], cwd=repo_path, capture_output=True)
        
        # Check for uncommitted changes
        status = run_command(['git', 'status', '--porcelain'], cwd=repo_path, capture_output=True)
        if status.stdout.strip():
            logger.warning(f"Uncommitted changes in {repo_name}")
            # Try to stash changes
            try:
                run_command(['git', 'stash', 'push', '-m', f'Auto-stash for {repo_name}'], cwd=repo_path)
                logger.info(f"Stashed local changes in {repo_name}")
                # Pull with rebase
                run_command(['git', 'pull', '--rebase'], cwd=repo_path)
                # Try to pop stash
                try:
                    run_command(['git', 'stash', 'pop'], cwd=repo_path)
                    logger.info(f"Reapplied stashed changes in {repo_name}")
                except subprocess.CalledProcessError:
                    logger.warning(f"Conflicts in {repo_name}. Run 'git stash pop' manually to resolve.")
            except subprocess.CalledProcessError as e:
                logger.error(f"Failed to update {repo_name}: {e}")
                return False
        else:
            # No local changes, safe to pull
            run_command(['git', 'pull'], cwd=repo_path)
        return True
    except subprocess.CalledProcessError as e:
        logger.error(f"Git operation failed for {repo_name}: {e}")
        return False
    except Exception as e:
        logger.error(f"Unexpected error updating {repo_name}: {e}")
        return False


def check_internet() -> bool:
    """Check internet connectivity."""
    try:
        urllib.request.urlopen('https://www.google.com', timeout=5)
        return True
    except:
        return False


def main():
    """Main entry point."""
    installer = DotfilesInstaller()
    
    # Parse command line arguments
    if len(sys.argv) > 1:
        arg = sys.argv[1]
        if arg in ['--help', '-h']:
            print("Dotfiles Installer")
            print("\nUsage:")
            print("  ./dotfiles.py          # Interactive mode")
            print("  ./dotfiles.py --full   # Full installation")
            print("  ./dotfiles.py --shell  # Shell environment only")
            print("  ./dotfiles.py --python # Python environment only")
            sys.exit(0)
        elif arg == '--full':
            installer.run_full_install()
        elif arg == '--shell':
            installer.run_shell_only()
        elif arg == '--python':
            installer.run_python_only()
        else:
            print(f"Unknown option: {arg}")
            sys.exit(1)
    else:
        installer.run_interactive()


if __name__ == '__main__':
    main()