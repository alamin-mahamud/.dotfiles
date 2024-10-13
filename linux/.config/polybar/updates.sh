#!/bin/bash

# Check for updates using the appropriate package manager and install them
if command -v xbps-install &> /dev/null; then
  updates=$(xbps-install -Mun | wc -l)
  if [ "$updates" -gt 0 ]; then
    sudo xbps-install -yu
  fi
elif command -v pacman &> /dev/null; then
  updates=$(pacman -Qu | wc -l)
  if [ "$updates" -gt 0 ]; then
    sudo pacman -Syu --noconfirm
  fi
elif command -v apt &> /dev/null; then
  updates=$(apt list --upgradable 2>/dev/null | wc -l)
  if [ "$updates" -gt 0 ]; then
    sudo apt update && sudo apt upgrade -y
  fi
else
  updates=0
fi

# Write the number of updates to a file
echo "$updates" > "/tmp/updates"

# Print the update icon if there are updates
if [ "$updates" -ne "0" ]; then
  printf ""
fi
