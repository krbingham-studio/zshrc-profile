# ============================================
# Environment Variables & Path Configuration
# ============================================

# Core Environment
export KUBECONFIG="${HOME}/.kube/config"
export HOST_FILE=/etc/hosts

# Programming Languages & Tools
export JAVA_HOME="$BREW_PREFIX/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"

# .NET
export PATH="$BREW_PREFIX/opt/dotnet@8/bin:$PATH"
export PATH="$PATH:$HOME/.dotnet/tools"

# Docker environment
export DOCKER_CLIENT_TIMEOUT=120
export COMPOSE_HTTP_TIMEOUT=120

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # Load nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # Load nvm bash_completion

# Quidco CLI

# Path additions
path+=(
  "$HOME/Library/Python/3.9/bin"
  "$HOME/Git/apache-maven-3.8.6"
  "$HOME/.composer/vendor/bin"
  "$BREW_PREFIX/bin"
  "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
  "$PNPM_HOME"
)
export PATH

# Android SDK configuration (OS-specific)
if [[ "$IS_LINUX" == "true" ]]; then
  if [[ -d "$HOME/Android/Sdk" ]]; then
    export ANDROID_HOME=$HOME/Android/Sdk
    if [[ ":$PATH:" != *":$ANDROID_HOME/cmdline-tools/latest/bin:"* ]]; then
      export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
    fi
    if [[ ":$PATH:" != *":$ANDROID_HOME/platform-tools:"* ]]; then
      export PATH=$PATH:$ANDROID_HOME/platform-tools
    fi
  fi
elif [[ "$IS_MAC" == "true" ]]; then
  if [[ -d "$HOME/Library/Android/sdk" ]]; then
    export ANDROID_HOME=$HOME/Library/Android/sdk
    if [[ ":$PATH:" != *":$ANDROID_HOME/cmdline-tools/latest/bin:"* ]]; then
      export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
    fi
    if [[ ":$PATH:" != *":$ANDROID_HOME/platform-tools:"* ]]; then
      export PATH=$PATH:$ANDROID_HOME/platform-tools
    fi
  fi
fi

# SDKMAN (must be at end)
export SDKMAN_DIR="$HOME/.sdkman"
if [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
  source "$HOME/.sdkman/bin/sdkman-init.sh" 2> /dev/null || echo "⚠️  SDKMAN initialization failed (non-critical)"
fi

# Terminal-specific configurations
if [[ "$TERM_PROGRAM" == "WarpTerminal" ]]; then
  export WARP_IS_LOCAL_SHELL_SESSION="1"
  unset ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE
  # shellcheck disable=SC2034
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE=""
fi

# VS Code shell integration
[[ "$TERM_PROGRAM" == "vscode" ]] && . "$(code --locate-shell-integration-path zsh)"

# Zoxide (smart cd replacement)
if command -v zoxide > /dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# NVM auto-switch based on .nvmrc
if [[ -d "$NVM_DIR" ]]; then
  autoload -U add-zsh-hook
  load-nvmrc() {
    local nvmrc_path="$(nvm_find_nvmrc)"
    if [[ -n "$nvmrc_path" ]]; then
      local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")
      if [[ "$nvmrc_node_version" == "N/A" ]]; then
        nvm install
      elif [[ "$nvmrc_node_version" != "$(nvm version)" ]]; then
        nvm use --silent
      fi
    elif [[ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ]] && [[ "$(nvm version)" != "$(nvm version default)" ]]; then
      echo "Reverting to nvm default version"
      nvm use default --silent
    fi
  }
  add-zsh-hook chpwd load-nvmrc
  load-nvmrc
fi

# FZF configuration
if command -v fzf > /dev/null 2>&1; then
  # Auto-completion
  [[ $- == *i* ]] && source "$BREW_PREFIX/opt/fzf/shell/completion.zsh" 2> /dev/null
  # Key bindings (Ctrl-R for history, Ctrl-T for files)
  source "$BREW_PREFIX/opt/fzf/shell/key-bindings.zsh" 2> /dev/null

  # FZF default options
  export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi
# Command-not-found handler
command_not_found_handler() {
  local cmd="$1"
  echo "zsh: command not found: $cmd"

  # Suggest common typos
  case "$cmd" in
    gti) echo "💡 Did you mean: git" ;;
    dokcer) echo "💡 Did you mean: docker" ;;
    pytohn | pyhton) echo "💡 Did you mean: python" ;;
    node.js) echo "💡 Did you mean: node" ;;
    claer) echo "💡 Did you mean: clear" ;;
    cd..) echo "💡 Did you mean: cd .." ;;
  esac

  # Suggest installation via Homebrew
  if command -v brew > /dev/null 2>&1; then
    local formula=$(brew search "^$cmd$" 2> /dev/null | head -1)
    if [[ -n "$formula" ]]; then
      echo "📦 Install with: brew install $formula"
    fi
  fi

  return 127
}
