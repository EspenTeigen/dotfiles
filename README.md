# Dotfiles

Personal dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## What's included

| Directory        | Description                                  |
|------------------|----------------------------------------------|
| `zsh/`           | Zsh config with Oh My Zsh + Powerlevel10k    |
| `tmux/`          | Tmux config with plugins                     |
| `nvim/`          | Neovim config (LazyVim)                      |
| `ghostty/`       | Ghostty terminal config                      |
| `sway/`          | Sway window manager + Waybar                 |
| `catppuccin-mocha/` | Catppuccin Mocha color definitions         |
| `p10k/`          | Powerlevel10k prompt config                  |
| `pandoc/`        | Pandoc templates                             |
| `corne_v4/`      | Corne v4 keyboard firmware/config            |

## Install

See [README_INSTALL.md](README_INSTALL.md) for full instructions, or just:

```bash
./install.sh
```

## Update

```bash
./update.sh
```

## Machine-specific config

Copy `zsh/.zshrc.local.example` to `~/.zshrc.local` and uncomment what you need.
This file is gitignored.
