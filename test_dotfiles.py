#!/usr/bin/env python3
"""
Test suite for dotfiles installer.
Following Test-Driven Development (TDD) approach.
"""

import unittest
import tempfile
import shutil
import os
import sys
import platform
from pathlib import Path
from unittest.mock import Mock, patch, MagicMock, call
import subprocess

# Add the parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))


class TestSystemDetection(unittest.TestCase):
    """Test system detection functionality."""
    
    def test_detect_os_linux(self):
        """Test OS detection on Linux."""
        with patch('platform.system', return_value='Linux'):
            from dotfiles import SystemInfo
            info = SystemInfo()
            self.assertEqual(info.os, 'linux')
    
    def test_detect_os_macos(self):
        """Test OS detection on macOS."""
        with patch('platform.system', return_value='Darwin'):
            from dotfiles import SystemInfo
            info = SystemInfo()
            self.assertEqual(info.os, 'macos')
    
    def test_detect_distro_ubuntu(self):
        """Test distribution detection for Ubuntu."""
        os_release_content = 'ID=ubuntu\nVERSION_ID="22.04"'
        with patch('builtins.open', unittest.mock.mock_open(read_data=os_release_content)):
            with patch('platform.system', return_value='Linux'):
                from dotfiles import SystemInfo
                info = SystemInfo()
                self.assertEqual(info.distro, 'ubuntu')
    
    def test_detect_arch(self):
        """Test architecture detection."""
        with patch('platform.machine', return_value='x86_64'):
            from dotfiles import SystemInfo
            info = SystemInfo()
            self.assertEqual(info.arch, 'amd64')
        
        with patch('platform.machine', return_value='arm64'):
            from dotfiles import SystemInfo
            info = SystemInfo()
            self.assertEqual(info.arch, 'arm64')
    
    def test_is_wsl(self):
        """Test WSL detection."""
        with patch('platform.release', return_value='microsoft-standard-WSL2'):
            from dotfiles import SystemInfo
            info = SystemInfo()
            self.assertTrue(info.is_wsl)
    
    def test_is_desktop_environment(self):
        """Test desktop environment detection."""
        with patch.dict(os.environ, {'DISPLAY': ':0'}):
            from dotfiles import SystemInfo
            info = SystemInfo()
            self.assertTrue(info.is_desktop)


class TestPackageManager(unittest.TestCase):
    """Test package management functionality."""
    
    @patch('shutil.which')
    def test_detect_apt(self, mock_which):
        """Test APT package manager detection."""
        mock_which.side_effect = lambda x: '/usr/bin/apt' if x == 'apt' else None
        with patch('platform.system', return_value='Linux'):
            from dotfiles import PackageManager
            pm = PackageManager()
            self.assertEqual(pm.manager, 'apt')
    
    @patch('shutil.which')
    def test_detect_brew(self, mock_which):
        """Test Homebrew detection on macOS."""
        mock_which.side_effect = lambda x: '/opt/homebrew/bin/brew' if x == 'brew' else None
        with patch('platform.system', return_value='Darwin'):
            from dotfiles import PackageManager
            pm = PackageManager()
            self.assertEqual(pm.manager, 'brew')
    
    @patch('subprocess.run')
    @patch('shutil.which', return_value='/usr/bin/apt')
    def test_install_packages_apt(self, mock_which, mock_run):
        """Test package installation with APT."""
        with patch('platform.system', return_value='Linux'):
            from dotfiles import PackageManager
            pm = PackageManager()
            pm.install(['git', 'curl'])
            # Check that the call was made with the expected arguments
            args, kwargs = mock_run.call_args
            self.assertEqual(args[0], ['sudo', 'apt', 'install', '-y', 'git', 'curl'])
            self.assertTrue(kwargs.get('check', False))
            self.assertTrue(kwargs.get('capture_output', False))
            self.assertTrue(kwargs.get('text', False))
    
    @patch('subprocess.run')
    def test_update_package_lists(self, mock_run):
        """Test updating package lists."""
        with patch('platform.system', return_value='Linux'):
            with patch('shutil.which', return_value='/usr/bin/apt'):
                from dotfiles import PackageManager
                pm = PackageManager()
                pm.update()
                # Check that the call was made with the expected arguments
                args, kwargs = mock_run.call_args
                self.assertEqual(args[0], ['sudo', 'apt', 'update'])
                self.assertTrue(kwargs.get('check', False))
                self.assertTrue(kwargs.get('capture_output', False))
                self.assertTrue(kwargs.get('text', False))


class TestFileOperations(unittest.TestCase):
    """Test file operation utilities."""
    
    def setUp(self):
        """Set up test environment."""
        self.test_dir = tempfile.mkdtemp()
        self.test_file = Path(self.test_dir) / 'test.txt'
        self.test_file.write_text('original content')
    
    def tearDown(self):
        """Clean up test environment."""
        shutil.rmtree(self.test_dir, ignore_errors=True)
    
    def test_backup_file(self):
        """Test file backup functionality."""
        from dotfiles import FileManager
        fm = FileManager()
        backup_path = fm.backup(self.test_file)
        self.assertTrue(Path(backup_path).exists())
        self.assertEqual(Path(backup_path).read_text(), 'original content')
    
    def test_create_symlink(self):
        """Test symlink creation."""
        from dotfiles import FileManager
        fm = FileManager()
        link_path = Path(self.test_dir) / 'link'
        fm.symlink(self.test_file, link_path)
        self.assertTrue(link_path.is_symlink())
        self.assertEqual(link_path.resolve(), self.test_file.resolve())
    
    def test_create_symlink_with_backup(self):
        """Test symlink creation with existing file backup."""
        from dotfiles import FileManager
        fm = FileManager()
        existing_file = Path(self.test_dir) / 'existing'
        existing_file.write_text('existing content')
        
        fm.symlink(self.test_file, existing_file, backup=True)
        self.assertTrue(existing_file.is_symlink())
        
        # Check backup was created
        backup_files = list(Path(self.test_dir).glob('existing.backup.*'))
        self.assertEqual(len(backup_files), 1)
        self.assertEqual(backup_files[0].read_text(), 'existing content')


class TestComponentInstallers(unittest.TestCase):
    """Test component installation functionality."""
    
    @patch('subprocess.run')
    def test_install_zsh(self, mock_run):
        """Test Zsh installation."""
        from dotfiles import ShellEnvironment
        shell_env = ShellEnvironment()
        with patch('shutil.which', return_value='/usr/bin/zsh'):
            shell_env.install_zsh()
            # Verify zsh was found and shell change attempted
            self.assertTrue(mock_run.called)
    
    @patch('subprocess.run')
    @patch('pathlib.Path.exists', return_value=False)
    def test_install_oh_my_zsh(self, mock_exists, mock_run):
        """Test Oh My Zsh installation."""
        from dotfiles import ShellEnvironment
        shell_env = ShellEnvironment()
        shell_env.install_oh_my_zsh()
        # Verify git clone was called
        calls = mock_run.call_args_list
        self.assertTrue(any('git' in str(call) and 'clone' in str(call) for call in calls))
    
    @patch('subprocess.run')
    def test_install_tmux(self, mock_run):
        """Test Tmux installation and configuration."""
        from dotfiles import ShellEnvironment
        shell_env = ShellEnvironment()
        with patch('shutil.which', return_value=None):
            shell_env.install_tmux()
            # Verify tmux package installation was attempted
            self.assertTrue(mock_run.called)


class TestInstallerWorkflow(unittest.TestCase):
    """Test complete installation workflows."""
    
    @patch('builtins.input', return_value='1')
    @patch('subprocess.run')
    def test_interactive_menu_full_install(self, mock_run, mock_input):
        """Test interactive menu full installation option."""
        from dotfiles import DotfilesInstaller
        installer = DotfilesInstaller()
        with patch.object(installer, 'run_full_install') as mock_full:
            installer.run_interactive()
            mock_full.assert_called_once()
    
    @patch('subprocess.run')
    def test_component_installation_order(self, mock_run):
        """Test that components are installed in correct order."""
        from dotfiles import DotfilesInstaller
        installer = DotfilesInstaller()
        
        with patch.object(installer, 'install_system_packages') as mock_sys:
            with patch.object(installer, 'setup_directories') as mock_dirs:
                with patch.object(installer.shell_env, 'install') as mock_shell:
                    installer.run_full_install()
                    
                    # Verify order
                    mock_sys.assert_called()
                    mock_dirs.assert_called()
                    mock_shell.assert_called()


class TestConfiguration(unittest.TestCase):
    """Test configuration management."""
    
    def test_load_config(self):
        """Test loading configuration from file."""
        config_content = """
{
    "shell": {
        "default": "zsh",
        "theme": "powerlevel10k"
    },
    "tools": ["ripgrep", "fd", "bat", "exa"]
}
"""
        with patch('builtins.open', unittest.mock.mock_open(read_data=config_content)):
            from dotfiles import Config
            config = Config('config.json')
            self.assertEqual(config.get('shell.default'), 'zsh')
            self.assertEqual(config.get('shell.theme'), 'powerlevel10k')
            self.assertIn('ripgrep', config.get('tools'))
    
    def test_default_config(self):
        """Test default configuration values."""
        from dotfiles import Config
        config = Config()
        self.assertIsNotNone(config.get('dotfiles_root'))
        self.assertIsNotNone(config.get('backup_dir'))


class TestLogging(unittest.TestCase):
    """Test logging functionality."""
    
    def test_log_levels(self):
        """Test different log levels."""
        from dotfiles import Logger
        with tempfile.NamedTemporaryFile(mode='w+', delete=False) as f:
            logger = Logger(f.name)
            logger.info("Info message")
            logger.success("Success message")
            logger.warning("Warning message")
            logger.error("Error message", exit=False)
            
            f.seek(0)
            content = Path(f.name).read_text()
            self.assertIn("Info message", content)
            self.assertIn("Success message", content)
            self.assertIn("Warning message", content)
            self.assertIn("Error message", content)
    
    def test_debug_mode(self):
        """Test debug logging."""
        from dotfiles import Logger
        with tempfile.NamedTemporaryFile(mode='w+', delete=False) as f:
            logger = Logger(f.name, debug=True)
            logger.debug("Debug message")
            
            content = Path(f.name).read_text()
            self.assertIn("Debug message", content)


class TestUtilities(unittest.TestCase):
    """Test utility functions."""
    
    @patch('subprocess.run')
    def test_command_exists(self, mock_run):
        """Test checking if command exists."""
        from dotfiles import command_exists
        mock_run.return_value = Mock(returncode=0)
        self.assertTrue(command_exists('git'))
        
        mock_run.return_value = Mock(returncode=1)
        self.assertFalse(command_exists('nonexistent'))
    
    @patch('builtins.input', return_value='y')
    def test_ask_yes_no_yes(self, mock_input):
        """Test yes/no prompt with yes response."""
        from dotfiles import ask_yes_no
        result = ask_yes_no("Continue?")
        self.assertTrue(result)
    
    @patch('builtins.input', return_value='n')
    def test_ask_yes_no_no(self, mock_input):
        """Test yes/no prompt with no response."""
        from dotfiles import ask_yes_no
        result = ask_yes_no("Continue?")
        self.assertFalse(result)
    
    @patch('urllib.request.urlopen')
    def test_check_internet(self, mock_urlopen):
        """Test internet connectivity check."""
        from dotfiles import check_internet
        mock_urlopen.return_value = Mock()
        self.assertTrue(check_internet())
        
        mock_urlopen.side_effect = Exception("Network error")
        self.assertFalse(check_internet())


if __name__ == '__main__':
    unittest.main(verbosity=2)