# Linux-specific configuration
# This file is only loaded on Linux systems (including WSL2)

# Homebrew location for Linux
if [[ -d "/home/linuxbrew/.linuxbrew" ]]; then
  export BREW_PREFIX="/home/linuxbrew/.linuxbrew"
elif [[ -d "$HOME/.linuxbrew" ]]; then
  export BREW_PREFIX="$HOME/.linuxbrew"
fi

# Add Linux-specific aliases or configurations here
# Example:
# alias open='xdg-open'
export PNPM_HOME="$HOME/.local/share/pnpm"

# Clipboard aliases (macOS compatibility)
if command -v xclip > /dev/null 2>&1; then
  alias pbcopy='xclip -selection clipboard'
  alias pbpaste='xclip -selection clipboard -o'
elif command -v xsel > /dev/null 2>&1; then
  alias pbcopy='xsel --clipboard --input'
  alias pbpaste='xsel --clipboard --output'
fi
