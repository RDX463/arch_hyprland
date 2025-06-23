#!/usr/bin/env bash
#───────────────────────────────────────────────────────────────────────────────
#  Hyperdots for Arch – unattended bootstrap script
#───────────────────────────────────────────────────────────────────────────────
#  What it does
#   1.  System update
#   2.  Installs all required packages (repo + AUR optional)
#   3.  Creates a ‘greeter’ user for gtkgreet
#   4.  Enables essential services (greetd, NetworkManager, bluetooth, etc.)
#   5.  Copies / symlinks dotfiles from this repo into $USER’s ~/.config
#   6.  Finishes with a reboot prompt
#
#  Usage
#   chmod +x install.sh
#   sudo ./install.sh <real-user>
#
#   <real-user> should be the desktop user you log in with (not root!).
#───────────────────────────────────────────────────────────────────────────────
set -Eeuo pipefail

#────────── 1. Pre-flight ─────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
  echo "❌  Run this script with sudo or as root." ; exit 1
fi

if [[ $# -lt 1 ]]; then
  echo "Usage: sudo $0 <desktop-user>"
  exit 1
fi
DESKTOP_USER=$1
HOME_DIR=$(eval echo "~$DESKTOP_USER")

GREEN=$(tput setaf 2) ; RESET=$(tput sgr0)
log(){ echo "${GREEN}==>${RESET} $*"; }

#────────── 2. Package lists ──────────────────────────────────────────────────
REPO_PKGS=(
  # Wayland stack
  hyprland hyprpaper hypridle hyprlock waybar
  # Apps / utilities
  rofi-lbonn-wayland foot thunar thunar-volman gvfs gvfs-smb
  network-manager-applet blueman bluez bluez-utils
  brightnessctl power-profiles-daemon
  swaybg grim slurp wl-clipboard playerctl jq curl
  xdg-desktop-portal-hyprland wf-recorder
  # Login / greeter
  greetd greetd-gtkgreet
  # Themes
  catppuccin-gtk-theme catppuccin-cursors-mocha catppuccin-icon-theme
  # optional VM helpers
  virt-viewer spice-vdagent
)

AUR_PKGS=( # leave empty for now – official repos already have everything
)

#────────── 3. System update & base packages ──────────────────────────────────
log "Updating system ..."
pacman -Syu --noconfirm

log "Installing repo packages ..."
pacman -S --needed --noconfirm "${REPO_PKGS[@]}"

#────────── 4. AUR helper (yay)  + AUR packages optional ──────────────────────
if [[ ${#AUR_PKGS[@]} -gt 0 ]]; then
  if ! command -v yay &>/dev/null; then
    log "Installing yay (AUR helper) ..."
    sudo -u "$DESKTOP_USER" bash -c "git clone https://aur.archlinux.org/yay.git /tmp/yay && \
        cd /tmp/yay && makepkg -si --noconfirm"
  fi
  log "Installing AUR packages ..."
  sudo -u "$DESKTOP_USER" yay -S --noconfirm --needed "${AUR_PKGS[@]}"
fi

#────────── 5. Enable services ────────────────────────────────────────────────
log "Enabling systemd services ..."
systemctl enable greetd.service
systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable power-profiles-daemon.service
systemctl enable systemd-oomd.service   # optional smart OOM killer

#────────── 6. Create greeter user (no-login) ─────────────────────────────────
if ! id greeter &>/dev/null; then
  log "Creating / configuring ‘greeter’ user ..."
  useradd -M -r -s /usr/bin/nologin greeter
fi
install -d -o greeter -g greeter -m 755 /var/db/greetd

cat >/etc/greetd/config.toml <<'EOF'
[terminal]
vt = 1

[default_session]
command = "gtkgreet -l --theme catppuccin"
user = "greeter"
EOF

#────────── 7. Deploy dotfiles from repo ──────────────────────────────────────
log "Deploying dotfiles for $DESKTOP_USER ..."

# assumes the script lives in the repo root; adjust if needed
REPO_DIR="$(cd "$(dirname "$0")"; pwd)"

install -d -m 755 "$HOME_DIR/.config"
# copy instead of symlink to avoid accidental deletions on removal of repo
rsync -avh --no-perms --no-owner --no-group \
  --exclude '.git/' \
  "$REPO_DIR/.config/" "$HOME_DIR/.config/"

chown -R "$DESKTOP_USER":"$DESKTOP_USER" "$HOME_DIR/.config"

# GTK theme defaults (Thunar etc.)
sudo -u "$DESKTOP_USER" gsettings set org.gnome.desktop.interface gtk-theme 'Catppuccin-Mocha-Standard-Blue-Dark' || true
sudo -u "$DESKTOP_USER" gsettings set org.gnome.desktop.interface icon-theme 'Catppuccin-Mocha'               || true
sudo -u "$DESKTOP_USER" gsettings set org.gnome.desktop.interface cursor-theme 'Catppuccin-Mocha-Dark-Cursors' || true

#────────── 8. Final touches ──────────────────────────────────────────────────
log "Installation finished ✔"
echo
echo "👉  Reboot now to land in the gtkgreet login screen."
read -rp "Reboot now? [y/N] " ans
if [[ $ans =~ ^[Yy]$ ]]; then
  reboot
fi