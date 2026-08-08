# macOS-specific configuration
# This file is only loaded on macOS systems

# Homebrew location for macOS
if [[ -d "/opt/homebrew" ]]; then
  export BREW_PREFIX="/opt/homebrew" # Apple Silicon
elif [[ -d "/usr/local" ]]; then
  export BREW_PREFIX="/usr/local" # Intel Mac
fi

export PNPM_HOME="$HOME/Library/pnpm"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # Load nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # Load nvm bash_completion

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
