#!/bin/bash

# Define monitor names
home_monitor_left="HDMI-0"
home_monitor_right="DP-4"

# Check if monitors are connected
left_connected=$(xrandr | grep "$home_monitor_left connected")
right_connected=$(xrandr | grep "$home_monitor_right connected")

# Apply xrandr configuration if monitors are connected
if [ -n "$left_connected" ] && [ -n "$right_connected" ]; then
    xrandr --output $home_monitor_left --mode 3440x1440 --pos 0x0 --rotate normal --primary \
           --output $home_monitor_right --mode 3440x1440 --pos 3440x0 --rotate normal
fi
