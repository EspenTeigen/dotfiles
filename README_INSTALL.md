# Dotfiles Installation

Quick setup for your development environment.

## Quick Install

```bash
./install.sh
```

## Manual Install

If you prefer to install components individually:

### Core Dependencies

```bash
# Debian/Ubuntu
sudo apt update
sudo apt install -y git curl wget zsh tmux neovim fzf stow ripgrep fd-find

# Arch
sudo pacman -S git curl wget zsh tmux neovim fzf stow ripgrep fd

# Fedora
sudo dnf install -y git curl wget zsh tmux neovim fzf stow ripgrep fd-find
```

### Sway (Optional)

```bash
# Debian/Ubuntu
sudo apt install -y sway waybar swaylock swayidle mako-notifier rofi wl-clipboard playerctl

# Arch
sudo pacman -S sway waybar swaylock swayidle mako rofi wl-clipboard playerctl

# Fedora
sudo dnf install -y sway waybar swaylock swayidle mako rofi wl-clipboard playerctl
```

### Shell Setup

```bash
# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install Zsh plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k"
```

### Tmux Plugin Manager

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

### Development Tools

```bash
# NVM (Node.js)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
source ~/.nvm/nvm.sh
nvm install --lts

# Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Go - download from https://go.dev/doc/install
```

### Nerd Fonts (Recommended)

```bash
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts

# FiraCode Nerd Font
curl -fLo "FiraCode.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip
unzip FiraCode.zip -d FiraCode
rm FiraCode.zip

fc-cache -fv
```

### Symlink Configs

```bash
cd ~/dotfiles

stow zsh
stow tmux
stow nvim
stow catppuccin-mocha
stow p10k

# Optional
stow sway      # if using Sway
stow ghostty   # if using Ghostty terminal
```

### Change Shell

```bash
chsh -s $(which zsh)
```

## Post-Install

1. **Terminal**: Restart your terminal or run `exec zsh`
2. **Tmux plugins**: Open tmux, press `Ctrl-a + Shift-i` to install plugins
3. **Neovim**: Open nvim - plugins will install automatically
4. **Prompt**: Run `p10k configure` to setup your prompt
5. **Sway**: Log out and select Sway from display manager

## Components

- **Shell**: Zsh with Oh My Zsh, Powerlevel10k theme
- **Terminal**: Ghostty (optional)
- **Multiplexer**: Tmux with custom theme and plugins
- **Editor**: Neovim with LazyVim
- **WM**: Sway (optional)
- **Theme**: Tokyo Night Dark / Catppuccin Mocha
- **Tools**: fzf, ripgrep, fd, nvm, cargo

## Troubleshooting

### Stow conflicts

If stow complains about existing files:

```bash
# Backup existing configs
mkdir -p ~/.config_backup
mv ~/.zshrc ~/.config_backup/
mv ~/.tmux.conf ~/.config_backup/
mv ~/.config/nvim ~/.config_backup/

# Then retry stow
stow zsh tmux nvim
```

### Tmux plugins not loading

Press `Ctrl-a + Shift-i` inside tmux to install plugins.

### Neovim errors

Delete and reinstall:

```bash
rm -rf ~/.local/share/nvim
rm -rf ~/.cache/nvim
nvim  # Will reinstall plugins
```
