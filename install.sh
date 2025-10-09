#!/usr/bin/env bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_command() {
    if command -v "$1" &>/dev/null; then
        log_success "$1 is already installed"
        return 0
    else
        return 1
    fi
}

# Detect package manager
if command -v apt &>/dev/null; then
    PKG_MANAGER="apt"
    INSTALL_CMD="sudo apt install -y"
    UPDATE_CMD="sudo apt update"
elif command -v dnf &>/dev/null; then
    PKG_MANAGER="dnf"
    INSTALL_CMD="sudo dnf install -y"
    UPDATE_CMD="sudo dnf check-update || true"
elif command -v pacman &>/dev/null; then
    PKG_MANAGER="pacman"
    INSTALL_CMD="sudo pacman -S --noconfirm"
    UPDATE_CMD="sudo pacman -Sy"
else
    log_error "Unsupported package manager. Please install dependencies manually."
    exit 1
fi

log_info "Detected package manager: $PKG_MANAGER"

# Update package lists
log_info "Updating package lists..."
$UPDATE_CMD

# Install system packages
log_info "Installing system packages..."

PACKAGES=(
    git
    curl
    wget
    zsh
    tmux
    neovim
    fzf
    stow
    ripgrep
    fd-find
    python3
    python3-numpy
    python3-pil
)

# Add sway packages if user wants it
read -p "Install Sway window manager and related tools? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    SWAY_PACKAGES=(
        sway
        waybar
        swaylock
        swayidle
        mako-notifier
        rofi
        wl-clipboard
        playerctl
    )
    PACKAGES+=("${SWAY_PACKAGES[@]}")

    # Add birdtray if available
    if [[ "$PKG_MANAGER" == "apt" ]]; then
        PACKAGES+=(birdtray)
    fi

    # Build mpvpaper for video wallpapers (optional)
    read -p "Install mpvpaper for video wallpapers? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] && ! check_command mpvpaper; then
        log_info "Building mpvpaper..."

        # Install build dependencies
        if [[ "$PKG_MANAGER" == "apt" ]]; then
            $INSTALL_CMD libmpv-dev meson ninja-build pkg-config libegl1-mesa-dev
        elif [[ "$PKG_MANAGER" == "pacman" ]]; then
            $INSTALL_CMD mpv meson ninja pkgconf mesa
        elif [[ "$PKG_MANAGER" == "dnf" ]]; then
            $INSTALL_CMD mpv-devel meson ninja-build pkgconfig mesa-libEGL-devel
        fi

        # Build and install
        BUILD_DIR=$(mktemp -d)
        git clone https://github.com/GhostNaN/mpvpaper.git "$BUILD_DIR"
        cd "$BUILD_DIR"
        meson build
        ninja -C build
        sudo ninja -C build install
        cd - > /dev/null
        rm -rf "$BUILD_DIR"

        log_success "mpvpaper installed"
    fi
fi

# Install packages based on package manager
for pkg in "${PACKAGES[@]}"; do
    # Package name mapping
    if [[ "$PKG_MANAGER" == "pacman" ]]; then
        case "$pkg" in
            "fd-find") pkg="fd" ;;
            "python3-numpy") pkg="python-numpy" ;;
            "python3-pil") pkg="python-pillow" ;;
        esac
    elif [[ "$PKG_MANAGER" == "dnf" ]]; then
        case "$pkg" in
            "python3-pil") pkg="python3-pillow" ;;
        esac
    fi

    if ! check_command "$pkg"; then
        log_info "Installing $pkg..."
        $INSTALL_CMD "$pkg" || log_warn "Failed to install $pkg"
    fi
done

# Install Ghostty (terminal emulator)
if ! check_command ghostty; then
    log_warn "Ghostty not found. Please install manually from: https://ghostty.org"
fi

# Install TPM (Tmux Plugin Manager)
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    log_info "Installing TPM (Tmux Plugin Manager)..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    log_success "TPM installed"
else
    log_success "TPM already installed"
fi

# Install Oh My Zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    log_info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    log_success "Oh My Zsh installed"
else
    log_success "Oh My Zsh already installed"
fi

# Install Zsh plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    log_info "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    log_success "zsh-autosuggestions installed"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    log_info "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    log_success "zsh-syntax-highlighting installed"
fi

if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
    log_info "Installing powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
    log_success "powerlevel10k installed"
fi

# Install NVM (Node Version Manager)
if [[ ! -d "$HOME/.nvm" ]]; then
    log_info "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    log_success "NVM installed"

    log_info "Installing latest LTS Node.js..."
    nvm install --lts
    log_success "Node.js installed"
else
    log_success "NVM already installed"
fi

# Install Rust via rustup
if ! check_command cargo; then
    log_info "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
    log_success "Rust installed"
fi

# Install Go
if ! check_command go; then
    log_warn "Go not installed. Install manually from: https://go.dev/doc/install"
fi

# Install Nerd Fonts
read -p "Install Nerd Fonts (recommended for icons)? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Installing Nerd Fonts..."
    mkdir -p ~/.local/share/fonts
    cd ~/.local/share/fonts

    # Download popular fonts
    FONTS=(
        "FiraCode"
        "JetBrainsMono"
        "Hack"
    )

    for font in "${FONTS[@]}"; do
        if [[ ! -d "$font" ]]; then
            log_info "Downloading $font..."
            curl -fLo "${font}.zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/${font}.zip"
            unzip -q "${font}.zip" -d "$font"
            rm "${font}.zip"
        fi
    done

    fc-cache -fv
    log_success "Fonts installed"
    cd - > /dev/null
fi

# Create wallpapers directory and symlink
log_info "Setting up wallpapers directory..."
mkdir -p ~/Pictures/wallpapers
if [[ ! -L "$DOTFILES_DIR/sway/.config/sway/wallpapers" ]]; then
    rm -rf "$DOTFILES_DIR/sway/.config/sway/wallpapers"
    ln -s ~/Pictures/wallpapers "$DOTFILES_DIR/sway/.config/sway/wallpapers"
fi

# Use stow to symlink dotfiles
log_info "Creating symlinks with stow..."
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

# Stow each config directory
CONFIGS=(
    "zsh"
    "tmux"
    "nvim"
)

# Add optional configs
if check_command sway; then
    CONFIGS+=("sway")
fi

if check_command ghostty; then
    CONFIGS+=("ghostty")
fi

# Always include theme files
CONFIGS+=("catppuccin-mocha" "p10k")

for config in "${CONFIGS[@]}"; do
    if [[ -d "$config" ]]; then
        log_info "Stowing $config..."
        stow -R "$config" || log_warn "Failed to stow $config (files might already exist)"
    fi
done

log_success "Dotfiles symlinked"

# Change default shell to zsh
if [[ "$SHELL" != "$(which zsh)" ]]; then
    log_info "Changing default shell to zsh..."
    chsh -s "$(which zsh)"
    log_success "Default shell changed to zsh"
fi

# Install Neovim plugins
log_info "Installing Neovim plugins..."
log_warn "First run of Neovim will install plugins. This may take a moment."

echo
log_success "Installation complete!"
echo
log_info "Next steps:"
echo "  1. Restart your terminal or run: exec zsh"
echo "  2. Open tmux and press prefix + I to install tmux plugins (Ctrl-a + Shift-i)"
echo "  3. Open nvim to install plugins automatically"
echo "  4. Run 'p10k configure' to configure your prompt"
echo
log_warn "If using Sway, log out and select Sway from your display manager"
