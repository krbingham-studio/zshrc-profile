# ============================================
# ZSH Configuration with Starship
# ============================================

# Detect OS (for compatibility across systems)
if [[ "$OSTYPE" == "darwin"* ]]; then
    export IS_MAC="true"
    export IS_LINUX="false"
else
    export IS_MAC="false"
    export IS_LINUX="true"
fi

# ============================================
# Homebrew Initialization
# ============================================

# Homebrew (must be early so commands are available)
if [[ "$IS_MAC" == "true" ]]; then
    # macOS Homebrew paths (Apple Silicon first, then Intel)
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
else
    # Linux Homebrew path
    if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
fi

# ============================================
# Core Shell Configuration
# ============================================

# Enable Starship prompt
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi

# Enable zoxide (smart cd)
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi

# History configuration
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# Performance: skip duplicate entries in $PATH
typeset -U path

# Zsh options
setopt AUTO_CD              # cd by just typing directory name
setopt HIST_VERIFY          # show command with history expansion before running
setopt SHARE_HISTORY        # share command history data
setopt HIST_IGNORE_SPACE    # ignore commands that start with space
setopt HIST_IGNORE_ALL_DUPS # ignore all duplicate commands in history
setopt HIST_SAVE_NO_DUPS    # don't save duplicates to history file
setopt HIST_REDUCE_BLANKS   # remove superfluous blanks from history
setopt CORRECT              # command auto-correction
setopt COMPLETE_ALIASES     # autocompletion for aliases
setopt EXTENDED_GLOB        # extended globbing
setopt NO_CASE_GLOB         # case insensitive globbing
setopt NUMERIC_GLOB_SORT    # sort numeric filenames numerically
setopt MENU_COMPLETE        # autoselect the first completion entry
setopt AUTO_LIST            # automatically list choices on ambiguous completion

# ============================================
# Completions
# ============================================

# Zsh completions with caching for faster startup
if type brew &>/dev/null; then  
  FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
  autoload -Uz compinit
  
  # Only regenerate .zcompdump once per day for better performance
  if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
    compinit
  else
    compinit -C
  fi
fi

# Enable colors
autoload -U colors && colors

# ============================================
# Zsh Plugins
# ============================================

# Cache brew prefix to avoid multiple subprocess calls
if type brew &>/dev/null && [[ -z "$BREW_PREFIX" ]]; then
    BREW_PREFIX=$(brew --prefix)
fi

if [[ -n "$BREW_PREFIX" ]]; then
    
    # zsh-autosuggestions
    if [[ -f "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
        source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
        ZSH_AUTOSUGGEST_STRATEGY=(history completion)
    fi
    
    # zsh-syntax-highlighting (not in Warp terminal)
    if [[ "$TERM_PROGRAM" != "WarpTerminal" ]] && [[ -f "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
        source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    fi
    
    # zsh-history-substring-search
    if [[ -f "$BREW_PREFIX/share/zsh-history-substring-search/zsh-history-substring-search.zsh" ]]; then
        source "$BREW_PREFIX/share/zsh-history-substring-search/zsh-history-substring-search.zsh"
    fi
fi

# ============================================
# Key Bindings
# ============================================

# History substring search
bindkey '^[[A' history-substring-search-up      # Up arrow
bindkey '^[[B' history-substring-search-down    # Down arrow
bindkey '^P' history-substring-search-up        # Ctrl+P
bindkey '^N' history-substring-search-down      # Ctrl+N

# Better history search
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# Navigation shortcuts
bindkey "^[[1;5C" forward-word              # Ctrl+Right arrow
bindkey "^[[1;5D" backward-word             # Ctrl+Left arrow
bindkey "^[[3~" delete-char                 # Delete key
bindkey "^[[H" beginning-of-line            # Home key
bindkey "^[[F" end-of-line                  # End key

# ============================================
# NVM Configuration
# ============================================

export NVM_DIR="$HOME/.nvm"
if [[ -n "$BREW_PREFIX" ]]; then
    [ -s "$BREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$BREW_PREFIX/opt/nvm/nvm.sh"
    [ -s "$BREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$BREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"
fi

# ============================================
# Load Modular Configurations
# ============================================

# Get the directory where this .zshrc is located
ZSHRC_DIR="${${(%):-%x}:A:h}"
ZSHCONFIG="$ZSHRC_DIR/config"

# Load separate config files
[[ -f "$ZSHCONFIG/exports.zsh" ]] && source "$ZSHCONFIG/exports.zsh"
[[ -f "$ZSHCONFIG/aliases.zsh" ]] && source "$ZSHCONFIG/aliases.zsh"
[[ -f "$ZSHCONFIG/functions.zsh" ]] && source "$ZSHCONFIG/functions.zsh"
[[ -f "$ZSHCONFIG/git.zsh" ]] && source "$ZSHCONFIG/git.zsh"

# Load OS-specific configurations
if [[ "$IS_MAC" == "true" ]]; then
    [[ -f "$ZSHCONFIG/macos.zsh" ]] && source "$ZSHCONFIG/macos.zsh"
else
    [[ -f "$ZSHCONFIG/linux.zsh" ]] && source "$ZSHCONFIG/linux.zsh"
fi

# Load secrets from separate file (tokens, API keys, etc.)
[[ -f "$HOME/.zsh_secrets" ]] && source "$HOME/.zsh_secrets"

# ============================================
# Terminal-specific Configurations
# ============================================

# Warp terminal optimizations
if [[ "$TERM_PROGRAM" == "WarpTerminal" ]]; then
    export WARP_IS_LOCAL_SHELL_SESSION="1"
    unset ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE=""
fi

# VS Code shell integration
[[ "$TERM_PROGRAM" == "vscode" ]] && command -v code &>/dev/null && . "$(code --locate-shell-integration-path zsh)" 2>/dev/null

# ============================================
# Welcome Message
# ============================================

if [[ "$IS_LINUX" == "true" ]]; then
    echo "=========================================="
    echo " 🚀 Welcome to your WSL2 development environment!"
    echo " ⚡ Powered by Starship prompt"
    echo " 📝 Type 'zshconfig' to edit ZSH config"
    echo " 🎨 Type 'starshipconfig' to edit Starship"
    echo " 🔄 Type 'update' to update system & Homebrew"
    echo "=========================================="
else
    echo "=========================================="
    echo " 🚀 Welcome to your macOS development environment!"
    echo " ⚡ Powered by Starship prompt"
    echo " 📝 Type 'zshconfig' to edit ZSH config"
    echo " 🎨 Type 'starshipconfig' to edit Starship"
    echo " 🔄 Type 'update' to update Homebrew"
    echo "=========================================="
fi

# Add newline to prompt
PROMPT="${PROMPT}"$'\n'
