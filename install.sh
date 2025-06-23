#!/bin/bash

# Exit on error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Error: Do not run this script as root. Use a regular user with sudo privileges.${NC}"
    exit 1
fi

# Check if yay is installed
if ! command -v yay &> /dev/null; then
    echo -e "${YELLOW}Installing yay AUR helper...${NC}"
    sudo pacman -S --needed base-devel git
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si
    cd -
    rm -rf /tmp/yay
fi

# Update system and install dependencies
echo -e "${GREEN}Updating system and installing dependencies...${NC}"
sudo pacman -Syu --needed \
    hyprland \
    waybar \
    rofi-wayland \
    swww \
    kitty \
    thunar \
    grim \
    slurp \
    swappy \
    lxappearance \
    ttf-jetbrains-mono \
    ttf-font-awesome \
    dunst \
    pavucontrol \
    brightnessctl \
    pamixer \
    papirus-icon-theme \
    mesa \
    libegl \
    libgl \
    libgles \
    libdrm \
    wayland \
    wayland-protocols \
    xorg-server \
    xorg-xwayland \
    fontconfig \
    network-manager \
    bluez \
    bluez-utils \
    power-profiles-daemon

# Install AUR packages
echo -e "${GREEN}Installing AUR packages...${NC}"
yay -S --needed \
    catppuccin-gtk-theme-mocha \
    catppuccin-cursors-mocha

# Enable NetworkManager and Bluetooth services
echo -e "${GREEN}Enabling NetworkManager and Bluetooth services...${NC}"
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth

# Create necessary directories
echo -e "${GREEN}Creating directories...${NC}"
mkdir -p ~/.config/{hypr,waybar,rofi,gtk-3.0,kitty}
mkdir -p ~/.config/hypr/scripts
mkdir -p ~/Pictures/wallpapers
mkdir -p ~/.cache

# Copy dotfiles
echo -e "${GREEN}Copying dotfiles...${NC}"
rsync -av --exclude='.git*' ./config/ ~/.config/
rsync -av ./wallpapers/ ~/Pictures/wallpapers/

# Set permissions
echo -e "${GREEN}Setting permissions...${NC}"
chmod +x ~/.config/hypr/scripts/*.sh

# Apply GTK and cursor themes
echo -e "${GREEN}Applying GTK and cursor themes...${NC}"
cat > ~/.config/gtk-3.0/settings.ini << EOF
[Settings]
gtk-theme-name=Catppuccin-Mocha
gtk-icon-theme-name=Papirus
gtk-cursor-theme-name=Catppuccin-Mocha
gtk-font-name=JetBrains Mono 12
EOF

# Apply kitty configuration
echo -e "${GREEN}Applying kitty configuration...${NC}"
cat > ~/.config/kitty/kitty.conf << EOF
font_family      JetBrains Mono
font_size        12
background       #1e1e2e
foreground       #cdd6f4
cursor           #f5e0dc
EOF

# Verify keybind and wallpaper dependencies
echo -e "${GREEN}Verifying dependencies...${NC}"
for cmd in kitty rofi thunar grim slurp swww nm-connection-editor blueman-manager brightnessctl powerprofilesctl; do
    if ! command -v "$cmd" &> /dev/null; then
        echo -e "${RED}Error: $cmd not found. Attempting to install...${NC}"
        sudo pacman -S --needed "$cmd"
        if ! command -v "$cmd" &> /dev/null; then
            echo -e "${RED}Error: Failed to install $cmd. Please install it manually.${NC}"
            exit 1
        fi
    fi
done

# Verify wallpaper directory
if [ -z "$(ls -A ~/Pictures/wallpapers)" ]; then
    echo -e "${YELLOW}Warning: No wallpapers found in ~/Pictures/wallpapers. Please add some images.${NC}"
fi

# Test kitty
echo -e "${GREEN}Testing kitty...${NC}"
if ! kitty --version; then
    echo -e "${RED}Error: kitty failed to run. Check logs with 'kitty --debug-rendering'.${NC}"
    exit 1
fi

# Optional: Set up SDDM for graphical login
echo -e "${YELLOW}Would you like to install and enable SDDM? (y/n)${NC}"
read -r install_sddm
if [ "$install_sddm" = "y" ] || [ "$install_sddm" = "Y" ]; then
    echo -e "${GREEN}Installing SDDM...${NC}"
    sudo pacman -S --needed sddm
    sudo systemctl enable sddm
fi

# Completion message
echo -e "${GREEN}Installation complete!${NC}"
echo -e "To launch Hyprland, run 'Hyprland' from a TTY or select the Hyprland session in your display manager."
echo -e "If you installed SDDM, reboot to use it: ${YELLOW}sudo reboot${NC}"
echo -e "If keybinds, kitty, or Waybar modules fail, check ~/.config/hypr/hyprland.conf, ~/.config/kitty/kitty.conf, ~/.config/waybar/config, and ensure VirtualBox isn't capturing the SUPER key."
