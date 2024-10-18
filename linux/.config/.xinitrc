#!/bin/sh

# Load X resources
if [ -f "$HOME/.Xresources" ]; then
    xrdb -merge "$HOME/.Xresources"
fi

# Set the keyboard layout
setxkbmap us

# Start the compositor (picom)
if command -v picom >/dev/null 2>&1; then
    picom --config $HOME/.config/picom.conf &
fi

# Start the notification daemon
if command -v dunst >/dev/null 2>&1; then
    dunst &
fi

# Start the policy kit authentication agent
if command -v /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 >/dev/null 2>&1; then
    /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 &
fi

# Start the network manager applet
if command -v nm-applet >/dev/null 2>&1; then
    nm-applet &
fi

# Start the volume control applet
if command -v volumeicon >/dev/null 2>&1; then
    volumeicon &
fi

# Start the clipboard manager
if command -v clipit >/dev/null 2>&1; then
    clipit &
fi

# Check the WM environment variable to determine which window manager to start
if [ "$WM" = "hyprland" ]; then
    # Start the hyprland window manager
    exec Hyprland
else
    # Default to i3 window manager
    exec i3
fi
