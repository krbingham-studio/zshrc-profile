# macOS-specific configuration
# This file is only loaded on macOS systems

# Homebrew location for macOS
if [[ -d "/opt/homebrew" ]]; then
  export BREW_PREFIX="/opt/homebrew" # Apple Silicon
elif [[ -d "/usr/local" ]]; then
  export BREW_PREFIX="/usr/local" # Intel Mac
fi

export PNPM_HOME="$HOME/Library/pnpm"
