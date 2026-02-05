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

# Quidco CLI

# Path additions
path+=(
  "$HOME/Library/Python/3.9/bin"
  "$HOME/Git/apache-maven-3.8.6"
  "$HOME/.composer/vendor/bin"
  "$BREW_PREFIX/bin"
  "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
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
