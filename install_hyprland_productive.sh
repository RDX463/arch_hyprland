#!/bin/bash

# Exit on any error
set -e

# Update system and install base development tools
echo "Updating system and installing base tools..."
sudo pacman -Syu --noconfirm
sudo pacman -S --needed base-devel git

# Install yay if not already installed
if ! command -v yay &> /dev/null; then
    echo "Installing yay..."
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
fi

# Install required packages
echo "Installing Hyprland and dependencies..."
packages=(
    hyprland waybar kitty fastfetch swaybg brightnessctl playerctl blueberry networkmanager bluez bluez-utils
    pipewire pipewire-pulse pipewire-alsa pamixer grim slurp wofi rofi-wayland qt5-wayland qt6-wayland
    power-profiles-daemon greetd greetd-tuigreet ttf-fira-code
)
for pkg in "${packages[@]}"; do
    if ! pacman -Qi "$pkg" &> /dev/null; then
        sudo pacman -S --noconfirm "$pkg" || { echo "Failed to install $pkg"; exit 1; }
    fi
done

# Manual installation for swaylock-effects (AUR package)
echo "Please install swaylock-effects from AUR:"
echo "If swaylock is installed, remove it first: sudo pacman -R swaylock"
echo "Then, install with: yay -S swaylock-effects"
echo "Note: You may need to resolve file conflicts, e.g., /etc/pam.d/swaylock"

# Enable services
echo "Enabling and starting services..."
sudo systemctl enable bluetooth
sudo systemctl start bluetooth
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager
sudo systemctl enable greetd

# Add user to video group for brightnessctl
sudo usermod -aG video $USER

# Create Hyprland config
mkdir -p ~/.config/hypr
cat << EOF > ~/.config/hypr/hyprland.conf
# Hyprland Configuration

# Monitor
monitor=,preferred,auto,1

# Input
input {
    kb_layout = us
    follow_mouse = 1
    sensitivity = 0
}

# General
general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)
}

# Animations
animations {
    enabled = yes
    bezier = myBezier, 0.05, 0.9, 0.1, 1.05
    animation = windows, 1, 7, myBezier
    animation = windowsOut, 1, 7, myBezier, popin 80%
    animation = border, 1, 10, default
    animation = fade, 1, 7, default
    animation = workspaces, 1, 6, default
}

# Decorations
decoration {
    rounding = 10
    blur {
        enabled = yes
        size = 3
        passes = 1
        new_optimizations = on
    }
    drop_shadow = yes
    shadow_range = 4
    shadow_render_power = 3
    col.shadow = rgba(1a1a1aee)
}

# Autostart
exec-once = waybar & swaybg -i /path/to/your/wallpapers/wallpaper1.jpg & blueberry-tray & nm-applet

# Keybindings for productivity
bind = \$mainMod, T, exec, kitty                   # Quick terminal access
bind = \$mainMod, C, killactive,                  # Close active window
bind = \$mainMod, M, exit,                        # Exit Hyprland
bind = \$mainMod, V, togglefloating,              # Toggle floating mode
bind = \$mainMod, W, exec, wofi --show drun       # App launcher
bind = \$mainMod, B, exec, blueberry              # Bluetooth manager
bind = \$mainMod, N, exec, nm-connection-editor   # Network manager
bind = \$mainMod, P, exec, powerprofilesctl       # Power profiles
bind = \$mainMod SHIFT, W, exec, wofi --show window # Window switcher
bind = \$mainMod, L, exec, swaylock               # Lock screen
bind = \$mainMod, R, exec, sh ~/wallpaper_changer.sh # Change wallpaper

# Workspace navigation
bind = \$mainMod, 1, workspace, 1
bind = \$mainMod, 2, workspace, 2
bind = \$mainMod, 3, workspace, 3
bind = \$mainMod SHIFT, 1, movetoworkspace, 1
bind = \$mainMod SHIFT, 2, movetoworkspace, 2
bind = \$mainMod SHIFT, 3, movetoworkspace, 3

# Variables
\$mainMod = SUPER
EOF

# Wallpaper changer script
cat << 'EOF' > ~/wallpaper_changer.sh
#!/bin/bash
WALLPAPERS=("/path/to/your/wallpapers/wallpaper1.jpg" "/path/to/your/wallpapers/wallpaper2.jpg" "/path/to/your/wallpapers/wallpaper3.jpg")
CURRENT=$(cat ~/.current_wallpaper 2>/dev/null || echo 0)
NEXT=$(( (CURRENT + 1) % ${#WALLPAPERS[@]} ))
swaybg -i "${WALLPAPERS[$NEXT]}" --mode fill &
echo "$NEXT" > ~/.current_wallpaper
sleep 0.5
hyprctl dispatch workspace 1
sleep 0.5
hyprctl dispatch workspace 1
EOF
chmod +x ~/wallpaper_changer.sh

# Power menu script
cat << 'EOF' > ~/power_menu.sh
#!/bin/bash
options="Shutdown\nReboot\nLogout"
choice=$(echo -e "$options" | wofi --dmenu -p "Power Menu")
case "$choice" in
    (Shutdown) systemctl poweroff ;;
    (Reboot) systemctl reboot ;;
    (Logout) hyprctl dispatch exit ;;
esac
EOF
chmod +x ~/power_menu.sh

# Waybar configuration
mkdir -p ~/.config/waybar
cat << EOF > ~/.config/waybar/config
{
    "layer": "top",
    "position": "top",
    "height": 30,
    "modules-left": ["hyprland/workspaces"],
    "modules-center": ["clock"],
    "modules-right": ["network", "bluetooth", "pulseaudio", "backlight", "power-profiles-daemon", "battery", "custom/power-menu", "custom/wallpaper-changer"],
    "hyprland/workspaces": {
        "format": "{name}",
        "persistent_workspaces": {
            "1": [],
            "2": [],
            "3": []
        }
    },
    "clock": {
        "format": "{:%H:%M}",
        "format-alt": "{:%Y-%m-%d}",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>"
    },
    "battery": {
        "format": "{capacity}% {icon}",
        "format-icons": ["", "", "", "", ""]
    },
    "pulseaudio": {
        "format": "{volume}% {icon}",
        "format-muted": "muted",
        "on-click": "pamixer -t"
    },
    "backlight": {
        "format": "{percent}% {icon}",
        "on-scroll-up": "brightnessctl set 5%+",
        "on-scroll-down": "brightnessctl set 5%-",
        "format-icons": ["☀️", "🌞"]
    },
    "network": {
        "interface": "wlan0",  // Change to your network interface
        "format": "{ifname}: {ipaddr}",
        "format-disconnected": "Disconnected"
    },
    "bluetooth": {
        "format": "{status}",
        "format-connected": "Bluetooth: ",
        "format-disconnected": "Bluetooth: "
    },
    "power-profiles-daemon": {
        "format": "{icon} {profile}",
        "format-icons": {
            "performance": "🚀",
            "balanced": "⚖️",
            "power-saver": "🔋"
        }
    },
    "custom/power-menu": {
        "format": "⏻",
        "on-click": "sh ~/power_menu.sh"
    },
    "custom/wallpaper-changer": {
        "format": "🖼️",
        "on-click": "sh ~/wallpaper_changer.sh"
    }
}
EOF

# Kitty configuration with fastfetch on startup
mkdir -p ~/.config/kitty
cat << EOF > ~/.config/kitty/kitty.conf
background_opacity 0.85
font_family Fira Code
font_size 12
enable_audio_bell no
scrollback_lines 10000
shell bash -c "fastfetch && exec bash"
EOF

# Fastfetch configuration
mkdir -p ~/.config/fastfetch
cat << EOF > ~/.config/fastfetch/config.conf
--logo none
--logo-padding-left 2
--title "Arch Linux"
--separator ">"
--color-keys 14
--color-title 14
--color-separator 7
--color-values 15
--display host
--display uptime
--display os
--display kernel
--display shell
--display cpu
--display gpu
--display memory
--display disk
--display battery
--display network
EOF

# Greetd configuration for login screen
sudo bash -c "cat << EOF > /etc/greetd/config.toml
[terminal]
vt = 1

[default_session]
command = \"Hyprland\"
user = \"$USER\"

[initial_session]
command = \"Hyprland\"
user = \"$USER\"
EOF"

# Swaylock-effects configuration for lock screen
mkdir -p ~/.config/swaylock
cat << EOF > ~/.config/swaylock/config
effect-blur = 7x5
effect-vignette = 0.5:0.5
indicator
indicator-radius = 100
indicator-thickness = 10
ring-color = ff0000
key-hl-color = 00ff00
line-color = 00000000
inside-color = 00000088
separator-color = 00000000
EOF

# Final instructions
echo "Installation complete."
echo "Please replace /path/to/your/wallpapers/ with your actual wallpaper path in ~/wallpaper_changer.sh and ~/.config/hypr/hyprland.conf"
echo "If desired, install a clipboard manager like clipman or copyq and integrate it with Waybar."
echo "Adjust the network interface in ~/.config/waybar/config if needed."
echo "For better wallpaper transitions, consider using swww."
echo "Reboot to apply changes."