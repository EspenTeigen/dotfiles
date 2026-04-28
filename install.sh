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

# Resolve dotfiles directory up front — used by swaylock-effects wallpaper copy
# and by the stow step at the bottom.
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

check_package() {
    case "$PKG_MANAGER" in
        apt) dpkg -s "$1" &>/dev/null ;;
        pacman) pacman -Q "$1" &>/dev/null ;;
        dnf) rpm -q "$1" &>/dev/null ;;
        *) return 1 ;;
    esac
}

# Clone a git repo to a temp dir, meson+ninja build, sudo install, clean up.
meson_build_install() {
    local repo_url="$1"
    local build_dir
    build_dir=$(mktemp -d)
    git clone --depth=1 "$repo_url" "$build_dir"
    (
        cd "$build_dir"
        meson setup build
        ninja -C build
        sudo ninja -C build install
    )
    rm -rf "$build_dir"
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
    # Full -Syu — partial upgrades on Arch are unsupported and break linking.
    UPDATE_CMD="sudo pacman -Syu --noconfirm"
else
    log_error "Unsupported package manager. Please install dependencies manually."
    exit 1
fi

log_info "Detected package manager: $PKG_MANAGER"

# Prime sudo so password prompts don't interrupt curl|bash steps later.
sudo -v

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
    fzf
    stow
    ripgrep
    fd-find
    unzip
    python3
    python3-numpy
    python3-pil
    pandoc
)
# Note: Neovim is intentionally NOT in PACKAGES — distro repos lag behind
# plugin requirements. It is installed via `bob` below (after Rust).

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

        meson_build_install https://github.com/GhostNaN/mpvpaper.git
        log_success "mpvpaper installed"
    fi

    # Build swaylock-effects for image backgrounds on lockscreen
    read -p "Install swaylock-effects for image lockscreen backgrounds? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Building swaylock-effects..."

        # Install build dependencies
        if [[ "$PKG_MANAGER" == "apt" ]]; then
            $INSTALL_CMD meson libwayland-dev libpam0g-dev libcairo2-dev libgdk-pixbuf2.0-dev libxkbcommon-dev
        elif [[ "$PKG_MANAGER" == "pacman" ]]; then
            $INSTALL_CMD meson wayland pam cairo gdk-pixbuf2 libxkbcommon
        elif [[ "$PKG_MANAGER" == "dnf" ]]; then
            $INSTALL_CMD meson wayland-devel pam-devel cairo-devel gdk-pixbuf2-devel libxkbcommon-devel
        fi

        meson_build_install https://github.com/mortie/swaylock-effects.git
        log_success "swaylock-effects installed"

        # Copy wallpapers if they exist
        if [[ -f "$DOTFILES_DIR/wallpapers/lockscreen.png" ]]; then
            log_info "Copying lockscreen wallpaper..."
            mkdir -p ~/Pictures
            cp "$DOTFILES_DIR/wallpapers/lockscreen.png" ~/Pictures/
            log_success "Lockscreen wallpaper installed"
        fi

        if [[ -f "$DOTFILES_DIR/wallpapers/cool-abstract-pixel-sunset-river-clouds-WIDE-5120-live-wallpaper-1.mp4" ]]; then
            log_info "Copying animated wallpaper..."
            mkdir -p ~/Pictures/wallpapers-animated
            cp "$DOTFILES_DIR/wallpapers/cool-abstract-pixel-sunset-river-clouds-WIDE-5120-live-wallpaper-1.mp4" ~/Pictures/wallpapers-animated/
            log_success "Animated wallpaper installed"
        fi
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

    if check_package "$pkg"; then
        log_success "$pkg is already installed"
    else
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
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
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

# Install bob (Neovim version manager) via cargo, then install latest stable
# Neovim through it. Distro Neovim is too old for modern plugins.
if ! check_command bob; then
    log_info "Installing bob (Neovim version manager)..."
    if command -v cargo &>/dev/null; then
        cargo install bob-nvim || log_warn "Failed to install bob"
    else
        log_warn "cargo not on PATH; skipping bob"
    fi
fi

if check_command bob; then
    log_info "Installing latest stable Neovim via bob..."
    bob use stable || log_warn "Failed to install Neovim via bob"
fi

# Install Go from the official tarball — distro packages often lag.
if ! check_command go; then
    log_info "Installing Go..."
    case "$(uname -m)" in
        x86_64)  GO_ARCH=amd64 ;;
        aarch64) GO_ARCH=arm64 ;;
        armv6l)  GO_ARCH=armv6l ;;
        *)       GO_ARCH="" ;;
    esac

    if [[ -z "$GO_ARCH" ]]; then
        log_warn "Unsupported arch $(uname -m) for Go auto-install; skipping"
    else
        GO_VERSION=$(curl -fsSL "https://go.dev/VERSION?m=text" | head -n 1)
        if [[ -z "$GO_VERSION" ]]; then
            log_warn "Could not determine latest Go version; skipping"
        else
            GO_TARBALL=$(mktemp --suffix=.tar.gz)
            if curl -fsSL "https://go.dev/dl/${GO_VERSION}.linux-${GO_ARCH}.tar.gz" -o "$GO_TARBALL"; then
                sudo rm -rf /usr/local/go
                sudo tar -C /usr/local -xzf "$GO_TARBALL"
                log_success "Go ${GO_VERSION} installed to /usr/local/go"
            else
                log_warn "Failed to download Go tarball"
            fi
            rm -f "$GO_TARBALL"
        fi
    fi
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
SWAY_WALLPAPERS="$DOTFILES_DIR/sway/.config/sway/wallpapers"
if [[ -L "$SWAY_WALLPAPERS" ]]; then
    :
elif [[ -e "$SWAY_WALLPAPERS" ]]; then
    log_warn "$SWAY_WALLPAPERS exists and is not a symlink; leaving it alone"
else
    ln -s ~/Pictures/wallpapers "$SWAY_WALLPAPERS"
fi

# Use stow to symlink dotfiles
log_info "Creating symlinks with stow..."
cd "$DOTFILES_DIR"

# Stow each config directory
CONFIGS=(
    "zsh"
    "tmux"
    "nvim"
)

# Add optional configs
if check_command sway; then
    CONFIGS+=("sway" "waybar" "rofi" "foot")
fi

# Always stow ghostty config — ghostty itself may be installed later by hand.
CONFIGS+=("ghostty")

# Always include theme files
CONFIGS+=("catppuccin-mocha" "p10k")

for config in "${CONFIGS[@]}"; do
    if [[ -d "$config" ]]; then
        log_info "Stowing $config..."
        stow -R "$config" || log_warn "Failed to stow $config (files might already exist)"
    fi
done

log_success "Dotfiles symlinked"

# Install Python packages for markdown PDF rendering.
# Newer distros enforce PEP 668 and reject plain --user; retry with
# --break-system-packages if the first attempt fails.
log_info "Installing Python packages for markdown PDF rendering..."
pip3 install --user weasyprint markdown 2>/dev/null \
    || pip3 install --user --break-system-packages weasyprint markdown \
    || log_warn "Failed to install Python packages"

# Install Neovim plugins
log_info "Installing Neovim plugins..."
log_warn "First run of Neovim will install plugins. This may take a moment."

# chsh prompts for a password — do it last so it can't halt the install mid-way.
if [[ "$SHELL" != "$(which zsh)" ]]; then
    log_info "Changing default shell to zsh..."
    chsh -s "$(which zsh)" || log_warn "Failed to change default shell (run 'chsh -s \$(which zsh)' manually)"
fi

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
