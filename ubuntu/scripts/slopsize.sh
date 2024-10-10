#!/usr/bin/env bash
# This script allows users to interactively select a region on the screen
# and then moves and resizes the currently active window in the i3 window manager
# to match the selected region. It uses 'slop' for region selection and 'xdotool'
# for window manipulation.

# Exit immediately if a command exits with a non-zero status and treat unset variables as an error.
set -eu

# Use 'slop' to interactively select a region on the screen.
# -b 3: Sets the border width of the selection box to 3 pixels.
# -c 0.96,0.5,0.09: Sets the color of the selection box to a shade of orange (RGB values).
# -t 0: Sets the border type to solid.
# -f "X=%x Y=%y W=%w H=%h": Formats the output to set the variables X, Y, W, and H to the selected region's coordinates and dimensions.
eval $(slop -b 3 -c 0.96,0.5,0.09 -t 0 -f "X=%x Y=%y W=%w H=%h")

# Enable floating mode for the currently active window in i3.
# Move the currently active window to the coordinates specified by X and Y.
# Resize the currently active window to the dimensions specified by W and H.
i3 floating enable && xdotool getactivewindow windowmove $X $Y && xdotool getactivewindow windowsize $W $H