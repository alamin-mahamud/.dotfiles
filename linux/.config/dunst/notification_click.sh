#!/bin/bash

# Extract the window ID or workspace name from the notification
# This example assumes the window ID is passed as the URL in the notification
WINDOW_ID=$(echo "$1" | grep -oP '(?<=window_id=)\w+')

# Focus the window using i3-msg
if [ -n "$WINDOW_ID" ]; then
    i3-msg "[id=\"$WINDOW_ID\"] focus"
fi
