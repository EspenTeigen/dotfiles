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

log_info "Updating dotfiles and plugins..."

# Update dotfiles repo
log_info "Pulling latest dotfiles..."
git pull origin main || log_warn "Failed to pull latest changes"

# Update Oh My Zsh
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log_info "Updating Oh My Zsh..."
    (cd "$HOME/.oh-my-zsh" && git pull) || log_warn "Failed to update Oh My Zsh"
fi

# Update Zsh plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    log_info "Updating zsh-autosuggestions..."
    (cd "$ZSH_CUSTOM/plugins/zsh-autosuggestions" && git pull) || log_warn "Failed to update zsh-autosuggestions"
fi

if [[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    log_info "Updating zsh-syntax-highlighting..."
    (cd "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" && git pull) || log_warn "Failed to update zsh-syntax-highlighting"
fi

if [[ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
    log_info "Updating powerlevel10k..."
    (cd "$ZSH_CUSTOM/themes/powerlevel10k" && git pull) || log_warn "Failed to update powerlevel10k"
fi

# Update TPM
if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
    log_info "Updating TPM..."
    (cd "$HOME/.tmux/plugins/tpm" && git pull) || log_warn "Failed to update TPM"
fi

# Update Tmux plugins
if command -v tmux &>/dev/null; then
    log_info "Updating tmux plugins..."
    if tmux list-sessions &>/dev/null; then
        log_warn "Tmux is running. Open tmux and press Ctrl-a + U to update plugins"
    else
        log_info "Start tmux and press Ctrl-a + U to update plugins"
    fi
fi

# Update NVM
if [[ -d "$HOME/.nvm" ]]; then
    log_info "Updating NVM..."
    (
        cd "$HOME/.nvm"
        git fetch --tags origin
        git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)`
    ) || log_warn "Failed to update NVM"
fi

# Update Rust
if command -v rustup &>/dev/null; then
    log_info "Updating Rust..."
    rustup update || log_warn "Failed to update Rust"
fi

# Update Neovim plugins
if command -v nvim &>/dev/null; then
    log_info "Updating Neovim plugins..."
    nvim --headless "+Lazy! sync" +qa || log_warn "Failed to update Neovim plugins"
fi

# Re-stow configs to ensure symlinks are current
log_info "Re-stowing configs..."
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DOTFILES_DIR"

CONFIGS=(
    "zsh"
    "tmux"
    "nvim"
    "catppuccin-mocha"
    "p10k"
)

if [[ -d "sway" ]] && command -v sway &>/dev/null; then
    CONFIGS+=("sway")
fi

if [[ -d "ghostty" ]] && command -v ghostty &>/dev/null; then
    CONFIGS+=("ghostty")
fi

for config in "${CONFIGS[@]}"; do
    if [[ -d "$config" ]]; then
        stow -R "$config" 2>/dev/null || log_warn "Stow conflict for $config - resolve manually"
    fi
done

log_success "Update complete!"
echo
log_info "Restart your terminal or run: exec zsh"
