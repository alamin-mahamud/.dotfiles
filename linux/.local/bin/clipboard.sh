#!/bin/bash

# Retrieve clipboard history using clipman
SELECTION=$(clipman pick --tool rofi --max-items 50)

clipman store --notify

# If a selection is made, copy it to the clipboard
if [ -n "$SELECTION" ]; then
  echo "$SELECTION" | xclip -selection clipboard
fi
