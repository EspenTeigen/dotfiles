# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Oh My Zsh configuration
export ZSH="$HOME/.oh-my-zsh"

# Theme - Catppuccin with powerlevel10k
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins for git superpowers and eye candy
plugins=(
    git
    git-extras
    git-flow
    gitignore
    github
    sudo
    history-substring-search
    zsh-autosuggestions
    zsh-syntax-highlighting
    colored-man-pages
    colorize
    command-not-found
    extract
    web-search
    copypath
    copyfile
    dirhistory
    jsontools
    safe-paste
    z
)

# Load Oh My Zsh (install if missing)
if [[ -f $ZSH/oh-my-zsh.sh ]]; then
    source $ZSH/oh-my-zsh.sh
else
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    source $ZSH/oh-my-zsh.sh
fi

# Install custom plugins if they don't exist
ZSH_CUSTOM=${ZSH_CUSTOM:-$ZSH/custom}

# Install zsh-autosuggestions
if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" &>/dev/null
fi

# Install zsh-syntax-highlighting
if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" &>/dev/null
fi

# Install powerlevel10k theme
if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k" &>/dev/null
fi

# Load Catppuccin colors
source ~/.catppuccin-mocha.zsh

# Environment variables
export EDITOR='nvim'
export VISUAL='nvim'
export BROWSER='firefox'

# History configuration
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_BEEP
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY

# Advanced Git aliases with eye candy
alias gs='git status -sb'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit -v'
alias gcm='git commit -m'
alias gca='git commit -av'
alias gcam='git commit -am'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gb='git branch -v'
alias gba='git branch -av'
alias gbd='git branch -d'
alias gbD='git branch -D'
alias gl='git log --oneline --decorate --graph --all'
alias glog='git log --oneline --decorate --graph'
alias glg='git log --stat'
alias glgp='git log --stat -p'
alias gp='git push'
alias gpo='git push origin'
alias gpu='git push -u origin'
alias gpf='git push --force-with-lease'
alias gpl='git pull'
alias gpr='git pull --rebase'
alias gf='git fetch'
alias gfa='git fetch --all'
alias gd='git diff'
alias gdc='git diff --cached'
alias gdh='git diff HEAD'
alias gdt='git diff-tree --no-commit-id --name-only -r'
alias gr='git remote -v'
alias gra='git remote add'
alias grm='git rm'
alias grmc='git rm --cached'
alias gst='git stash'
alias gstp='git stash pop'
alias gstl='git stash list'
alias gsts='git stash show'
alias gm='git merge'
alias gmf='git merge --no-ff'
alias gma='git merge --abort'
alias grb='git rebase'
alias grbi='git rebase -i'
alias grba='git rebase --abort'
alias grbc='git rebase --continue'

# Directory navigation with style
alias ls='ls --color=auto'
alias ll='ls -alFh --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias lt='ls -ltrh --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# System aliases
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias diff='diff --color=auto'
alias ip='ip --color=auto'
alias vim='nvim'
alias vi='nvim'

# Fun aliases
alias weather='curl wttr.in'
alias myip='curl ifconfig.me'
alias ports='netstat -tulanp'
alias meminfo='free -m -l -t'
alias psmem='ps auxf | sort -nr -k 4'
alias pscpu='ps auxf | sort -nr -k 3'
alias cpuinfo='lscpu'
alias gpumeminfo='grep -i --color memory /proc/meminfo'

# SSHFS aliases
alias mount-fi='sshfs NTE-FI-01-02:/home/pi ~/projects/frankenstein-dev -o idmap=user,uid=1000,gid=1000,allow_other,reconnect'

# Advanced functions
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Git functions with eye candy
gclone() {
    git clone "$1" && cd "$(basename "$1" .git)"
}

# Show git log with beautiful formatting
glog-pretty() {
    git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
}

# Git status with icons (if nerd fonts available)
gst-fancy() {
    echo "📊 Repository Status:"
    git status -sb
    echo ""
    echo "📈 Recent commits:"
    git log --oneline -5
}

# Extract function with progress
extract() {
    if [ -f "$1" ]; then
        echo "📦 Extracting $1..."
        case $1 in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar e "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "❌ '$1' cannot be extracted" ;;
        esac
        echo "✅ Done!"
    else
        echo "❌ '$1' is not a valid file"
    fi
}

# PATH additions
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# FZF integration with eye candy
if command -v fzf >/dev/null 2>&1; then
    # FZF key bindings and fuzzy completion
    if [[ -f ~/.fzf.zsh ]]; then
        source ~/.fzf.zsh
    elif [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
        source /usr/share/doc/fzf/examples/key-bindings.zsh
        source /usr/share/doc/fzf/examples/completion.zsh
    fi
    
    # FZF with Catppuccin colors
    export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --inline-info $CATPPUCCIN_FZF_OPTS"
fi

# Auto-suggestions with Catppuccin colors
if [[ -f "$ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=$CATPPUCCIN_OVERLAY0,bold"
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)
fi

# Better ls colors
if command -v dircolors >/dev/null 2>&1; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
fi


# Load local customizations
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
export PATH="$HOME/.local/bin:$PATH"
