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
            paru -S --noconfirm autoconf automake pkg-config pam-devel cairo \
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
    ubuntu_items="i3 i3status i3lock rofi dunst kitty alacritty maim picom feh thunar alsa-utils volumeicon-alsa brightnessctl bluez xclip pulseaudio xfce4-power-manager"
    arch_items="i3 i3status polybar rofi dunst kitty alacritty maim picom feh thunar alsa-utils volumeicon brightnessctl bluez bluez-utils network-manager-applet xclip pulseaudio pulseaudio-alsa pulseaudio-bluetooth xorg-xbacklight xorg-xprop xfce4-power-manager"

    case "$OS" in
        $UBUNTU) sudo apt install -y $ubuntu_items ;;
        $ARCH) paru -S --noconfirm $arch_items ;;
    esac

    echo "🔗 Setting up i3 symlinks..."
    setup_i3_lock_color
    setup_config i3
}
