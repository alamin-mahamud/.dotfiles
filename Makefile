# Makefile for dotfiles installation
# Python-based implementation

.PHONY: help install test clean full shell python desktop lint format check

# Default target
help:
	@echo "Dotfiles Installer - Python Implementation"
	@echo ""
	@echo "Usage:"
	@echo "  make install    - Run interactive installer"
	@echo "  make full       - Full installation (non-interactive)"
	@echo "  make shell      - Install shell environment only"
	@echo "  make python     - Install Python environment only"
	@echo "  make desktop    - Install desktop features only"
	@echo "  make test       - Run test suite"
	@echo "  make lint       - Run code linting"
	@echo "  make format     - Format code with black"
	@echo "  make clean      - Clean cache and temporary files"
	@echo "  make check      - Run all checks (test, lint)"

# Installation targets
install:
	@python3 dotfiles.py

full:
	@python3 dotfiles.py --full

shell:
	@python3 dotfiles.py --shell

python:
	@python3 dotfiles.py --python

desktop:
	@python3 -c "from dotfiles import DesktopEnvironment; DesktopEnvironment().install()"

# Testing and quality
test:
	@python3 -m pytest test_dotfiles.py -v

test-coverage:
	@python3 -m pytest test_dotfiles.py --cov=dotfiles --cov-report=html --cov-report=term

lint:
	@python3 -m flake8 dotfiles.py test_dotfiles.py --max-line-length=100 || true
	@python3 -m mypy dotfiles.py --ignore-missing-imports || true

format:
	@python3 -m black dotfiles.py test_dotfiles.py --line-length=100

check: test lint

# Maintenance
clean:
	@find . -type f -name "*.pyc" -delete
	@find . -type d -name "__pycache__" -delete
	@find . -type d -name "*.egg-info" -delete
	@rm -rf .pytest_cache .coverage htmlcov
	@rm -f /tmp/dotfiles_*.log
	@echo "Cleaned cache and temporary files"

# Compatibility with old shell scripts
bootstrap:
	@echo "Running Python-based installer..."
	@python3 dotfiles.py

# Development
dev-deps:
	@pip3 install --user pytest pytest-cov pytest-mock black flake8 mypy

# Backup current dotfiles
backup:
	@python3 -c "from dotfiles import FileManager; import os; from pathlib import Path; \
		fm = FileManager(); \
		for f in ['.zshrc', '.tmux.conf', '.gitconfig']: \
			p = Path.home() / f; \
			fm.backup(p) if p.exists() else None"

# Show system information
info:
	@python3 -c "from dotfiles import SystemInfo, Logger; \
		s = SystemInfo(); l = Logger(); \
		l.header('System Information'); \
		l.info(f'OS: {s.os}'); \
		l.info(f'Distribution: {s.distro}'); \
		l.info(f'Architecture: {s.arch}'); \
		l.info(f'WSL: {s.is_wsl}'); \
		l.info(f'Desktop: {s.is_desktop}'); \
		l.info(f'Display Server: {s.display_server}')"