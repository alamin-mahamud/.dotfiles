#!/bin/bash

# Function to install dependencies for i3lock-color
setup_i3_lock_color() {
    echo "🔧 Installing dependencies for i3lock-color..."
    case "$OS" in
        $UBUNTU)
            sudo apt install -y autoconf automake pkg-config libpam0g-dev libcairo2-dev \
                                libxcb1-dev libxcb-composite0-dev libxcb-xinerama0-dev \
                                libxcb-randr0-dev libev-dev libx11-xcb-dev libxcb-xkb-dev \
                                libxcb-image0-dev libxcb-util0-dev libxcb-xrm-dev \
                                libxcb-cursor-dev libxkbcommon-dev libxkbcommon-x11-dev \
                                libjpeg-dev
            ;;
        $ARCH)
            sudo pacman -S --noconfirm autoconf automake pkg-config pam-devel cairo \
                                xcb-util xcb-util-image xcb-util-keysyms xcb-util-renderutil \
                                xcb-util-wm xcb-util-xrm xcb-util-cursor xcb-util-xinerama \
                                libev xcb-util-xrandr xcb-util-xkb xkbcommon xkbcommon-x11 \
                                libjpeg-turbo
            ;;
    esac

    current_dir=$(pwd)
    echo "🔧 Cloning and installing i3lock-color..."
    git clone https://github.com/Raymo111/i3lock-color.git /tmp/i3lock-color
    cd /tmp/i3lock-color
    ./install-i3lock-color.sh
    echo "✅ i3lock-color installed successfully."
    cd "$current_dir"
}

# Function to install i3 and related tools
setup_i3() {
    echo "🖥️ Installing i3 and related tools..."
    case "$OS" in
        $UBUNTU)
            sudo apt install -y \
                # i3 window manager and status bar
                i3 i3status \

                # Additional UI components
                # bar, launcher, notifications
                polybar rofi dunst \

                # Terminal emulators
                kitty alacritty \

                # Screenshot and compositor
                maim picom \

                # Background and file manager
                feh thunar \

                # Audio and volume control
                alsa alsa-utils volumeicon-alsa \

                # Brightness and Bluetooth control
                brightnessctl bluetoothctl \

                # Network manager
                network-manager-gnome \

                # Clipboard manager
                xclip \

                # Audio server and modules
                pulseaudio pulseaudio-utils pulseaudio-module-bluetooth \

                # Backlight control
                xbacklight \

                # X11 utilities
                x11-utils \

                # Power manager
                xfce4-power-manager \
            ;;
        $ARCH)
            sudo pacman -S --noconfirm \
                # i3 window manager and status bar
                i3-wm i3status i3lock \

                # Additional UI components
                polybar rofi dunst \

                # Terminal emulators
                kitty alacritty \

                # Screenshot and compositor
                maim picom \

                # Background and file manager
                feh thunar \

                # Audio and volume control
                alsa-utils volumeicon \

                # Brightness and Bluetooth control
                brightnessctl bluez-utils \

                # Network manager
                network-manager-applet \

                # Clipboard manager
                xclip \

                # Audio server and modules
                pulseaudio pulseaudio-alsa pulseaudio-bluetooth \

                # Backlight control
                xorg-xbacklight \

                # Xorg utilities
                xorg-server xorg-xinit xorg-xauth xorg-xprop \

                # Power manager
                xfce4-power-manager                          \

                # Additional utilities
                jq
            ;;
    esac

    echo "🔗 Setting up i3 symlinks..."
    setup_i3_lock_color
    setup_config i3
}
