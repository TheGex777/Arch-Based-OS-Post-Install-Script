#!/bin/bash
# =============================================================================
#  Arch Linux Post-Install Setup Script (2026 Edition)
# - Installs development, productivity, and utility packages
# - Handles official repos + AUR cleanly
# - Sets up Flatpak + Flathub
# - Configures basic firewall (ufw) safely
# - Robust error handling and user feedback
# =============================================================================

set -euo pipefail  # Exit on errors, undefined vars, pipe failures

echo "=== 🚀 Arch Linux Post-Install Script ==="

# ====================== PACKAGE LISTS ======================

# Official repositories
pacman_packages=(
    # Development & Build tools
    base-devel clang cmake ninja git
    # Virtualization
    virtualbox virtualbox-guest-iso virtualbox-host-modules-arch
    # System & Utilities
    gparted filelight bleachbit ufw gufw apparmor
    # Media & Productivity
    vlc audacious libreoffice-fresh gnucash cherrytree
    # Java
    jre17-openjdk jdk17-openjdk
    # Editors & IDEs
    emacs neofetch
    # Web & JS
    nodejs npm
    # Android development
    android-studio
)

# AUR packages (via yay)
aur_packages=(
    onlyoffice-bin
    vscodium-bin
)

# Optional popular Flatpak apps (uncomment what you want)
flatpak_apps=(
    # com.spotify.Client
    # com.discordapp.Discord
    # org.signal.Signal
    # com.github.tchx84.Flatseal          # Flatpak permission manager
    # org.mozilla.firefox
)

# ====================== FUNCTIONS ======================

check_and_install_yay() {
    if ! command -v yay >/dev/null 2>&1; then
        echo "→ yay not found. Installing from AUR..."
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay
        makepkg -si --noconfirm
        cd - >/dev/null
        rm -rf /tmp/yay
        echo "→ yay installed."
    else
        echo "→ yay is already installed."
    fi
}

update_system() {
    echo "→ Updating system (pacman -Syu)..."
    sudo pacman -Syu --noconfirm
}

install_pacman_packages() {
    echo "→ Installing official packages..."
    for pkg in "${pacman_packages[@]}"; do
        if pacman -Qs "^${pkg}$" >/dev/null 2>&1; then
            echo "   [SKIP] $pkg (already installed)"
        else
            echo "   [INSTALL] $pkg"
            sudo pacman -S --needed --noconfirm "$pkg"
        fi
    done
}

install_aur_packages() {
    echo "→ Installing AUR packages..."
    for pkg in "${aur_packages[@]}"; do
        if pacman -Qs "^${pkg}$" >/dev/null 2>&1; then
            echo "   [SKIP] $pkg (already installed)"
        else
            echo "   [AUR] $pkg"
            yay -S --needed --noconfirm "$pkg"
        fi
    done
}

setup_flatpak() {
    echo "→ Setting up Flatpak..."
    sudo pacman -S --needed --noconfirm flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    if [ ${#flatpak_apps[@]} -gt 0 ]; then
        echo "→ Installing selected Flatpak apps..."
        for app in "${flatpak_apps[@]}"; do
            echo "   [FLATPAK] $app"
            flatpak install -y --noninteractive flathub "$app"
        done
    else
        echo "   (No Flatpak apps selected — you can add them in the script)"
    fi
}

configure_firewall() {
    echo "→ Configuring firewall (ufw)..."
    # Ensure ufw is enabled as service (Arch-specific)
    sudo systemctl enable --now ufw.service 2>/dev/null || true

    # Basic safe defaults: allow SSH (with rate limit), deny incoming by default
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw limit ssh/tcp comment 'Rate-limited SSH' || true

    # Optional: allow VirtualBox or other services if needed
    # sudo ufw allow from 192.168.0.0/16 to any port 3389 comment 'RDP' || true

    sudo ufw --force enable
    echo "   ufw status:"
    sudo ufw status verbose
}

# ====================== MAIN EXECUTION ======================

echo "Starting enhanced setup..."

# Prerequisites
sudo pacman -S --needed --noconfirm git base-devel

check_and_install_yay
update_system
install_pacman_packages
install_aur_packages
setup_flatpak
configure_firewall

echo "=================================================="
echo "✅ Setup completed successfully!"
echo ""
echo "Recommendations:"
echo "   • Reboot your system now:   sudo reboot"
echo "   • Check firewall:           sudo ufw status"
echo "   • Manage Flatpaks:          flatpak list"
echo "   • Add more Flatpaks by editing the flatpak_apps array"
echo "   • Consider installing xdg-desktop-portal for better Flatpak integration"
echo "     (e.g., xdg-desktop-portal-gtk or -kde depending on your DE)"
echo "=================================================="

# Optional: remind about common next steps
echo "Next steps you might want:"
echo "   - Install a desktop environment if not already done"
echo "   - Set up timeshift for backups"
echo "   - Install fonts (nerd-fonts, ttf-ms-fonts from AUR)"
echo "   - Configure apparmor profiles"
