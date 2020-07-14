#!/bin/zsh


set -e


# --- General ---

# Maximize windows on double clicking them:
defaults write -g AppleActionOnDoubleClick 'Maximize'


# --- Dock ---

# Automatically hide and show the Dock
defaults write com.apple.dock autohide -bool true


# -- Finder ---

# Keep folders on top when sorting by name:
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Show file extensions in Finder:
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Allow quitting Finder via ⌘ + Q; doing so will also hide desktop icons
defaults write com.apple.finder QuitMenuItem -bool true


# --- Safari ---

# Privacy: don’t send search queries to Apple
defaults write com.apple.Safari UniversalSearchEnabled -bool false
defaults write com.apple.Safari SuppressSearchSuggestions -bool true


# --- Text Editing ---

# Disable smart quotes:
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable autocorrect:
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Disable auto-capitalization:
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false


# --- Calendar ---                                                              

# Show week numbers (10.8 only)
defaults write com.apple.iCal "Show Week Numbers" -bool true

# Week starts on monday
defaults write com.apple.iCal "first day of week" -int 1


# --- Restarting apps whose settings were changed: ---

echo
echo 'Restarting apps...'

for app in "Calendar" "Dock" "Finder"; do
	killall "${app}" &> /dev/null
done

echo
echo 'MacOS Defaults updated!'


# Ref - https://github.com/webpro/dotfiles/blob/master/macos/defaults.sh
