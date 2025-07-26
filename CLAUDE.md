# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal dotfiles repository for configuring development environments across Linux and macOS systems. The repository contains configuration files, themes, and automated setup scripts for multiple window managers, shells, and development tools.

## Key Commands

### System Setup
- `./bootstrap.sh` - Main entry point that detects OS and runs appropriate setup
- `chmod +x ./bootstrap.sh` - Make bootstrap script executable before running

### Platform-Specific Setup
- Linux: `source linux/install.sh` (called automatically by bootstrap)
- macOS: `source macos/install.sh` (called automatically by bootstrap)

### Manual Setup Components
- `source linux/symlinks.sh` - Create symlinks for configuration files (Linux)
- `source linux/python.sh` - Install Python development environment
- `source linux/i3.sh` - Install i3 window manager setup
- `source linux/hyprland.sh` - Install Hyprland compositor setup

## Architecture

### Directory Structure
- `bootstrap.sh` - OS detection and main setup orchestration
- `linux/` - Linux-specific configurations and install scripts
  - `install.sh` - Main Linux setup script with package installation
  - `symlinks.sh` - Creates symlinks from dotfiles to home directory
  - `python.sh`, `i3.sh`, `hyprland.sh` - Component-specific setup
  - `.config/` - Application configuration files
  - `grub/themes/` - GRUB bootloader themes (Catppuccin variants)
- `macos/` - macOS-specific configurations
  - `install.sh` - Homebrew-based setup for macOS
  - `python.sh` - Python environment setup for macOS
- `zsh/` - Zsh shell configuration split into modular files
  - `.zshrc` - Main zsh configuration that sources other modules
  - `aliases.zsh`, `exports.zsh`, `functions.zsh`, etc. - Modular config files
- `git/` - Git configuration files
  - `.gitconfig` - Global Git configuration
  - `.gitmessage` - Commit message template

### Configuration Strategy
The repository uses a symlink-based approach where:
1. Dotfiles remain in the repository directory
2. Setup scripts create symlinks from `$HOME` to the repository files
3. This allows version control of all configurations while keeping them in standard locations

### Key Variables
- `DOT` or `dots` - Points to `$HOME/Work/.dotfiles` (repository location)
- `SCRIPT_DIR` - Dynamic path to current script directory
- Platform detection via `$OSTYPE` and `/etc/os-release`

### Window Manager Support
The Linux setup supports multiple desktop environments:
- **ubuntu_basic** - Basic Ubuntu setup with Kitty terminal
- **i3** - i3 window manager with Polybar, Rofi, Picom
- **hyprland** - Hyprland Wayland compositor with Waybar, Wofi

### Python Environment
Uses modern Python toolchain:
- `pyenv` for Python version management
- `pipenv` for project-specific virtual environments
- `pipx` for global Python tool installation

## Important Notes

- The repository expects to be cloned to `$HOME/Work/.dotfiles`
- Linux scripts include sudoers configuration for passwordless package management
- Font installation includes Nerd Fonts (FiraCode, JetBrainsMono, Iosevka)
- Zsh configuration depends on Oh My Zsh framework
- Git configuration includes personal user details that should be updated