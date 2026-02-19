# ============================================
# Custom Utility Functions
# ============================================

# Auto-update zshrc repository
update_zshrc_repo() {
  local repo_dir="${ZSHRC_DIR}"
  local previous_dir="$PWD"

  cd "$repo_dir" 2> /dev/null || return
  git fetch origin main --quiet 2> /dev/null
  local local_hash=$(git rev-parse HEAD 2> /dev/null)
  local remote_hash=$(git rev-parse origin/main 2> /dev/null)

  if [[ "$local_hash" != "$remote_hash" ]]; then
    if git pull origin main --quiet 2> /dev/null; then
      echo "[zshrc] ✓ Configuration updated from repository"

      # Reload config files to apply changes immediately
      [[ -f "$ZSHCONFIG/exports.zsh" ]] && source "$ZSHCONFIG/exports.zsh"
      [[ -f "$ZSHCONFIG/aliases.zsh" ]] && source "$ZSHCONFIG/aliases.zsh"
      [[ -f "$ZSHCONFIG/functions.zsh" ]] && source "$ZSHCONFIG/functions.zsh"
      [[ -f "$ZSHCONFIG/git.zsh" ]] && source "$ZSHCONFIG/git.zsh"

      echo "[zshrc] ✓ Configuration reloaded"
    else
      echo "[zshrc] ⚠ Update available but could not pull (may have local changes)"
    fi
  fi

  cd "$previous_dir"
}

# Setup global git hooks from this repo
setup_git_hooks() {
  local repo_hooks="${ZSHRC_DIR}/hooks"

  if [[ ! -d "$repo_hooks" ]]; then
    echo "⚠️  No hooks directory found at $repo_hooks"
    return 1
  fi

  # Configure git to use hooks directory directly from this repo
  git config --global core.hooksPath "$repo_hooks"

  # Make all hooks executable
  chmod +x "$repo_hooks"/*

  echo "✓ Global git hooks configured"
  echo "Hooks location: $repo_hooks"
  echo ""
  echo "Available hooks:"
  for hook in "$repo_hooks"/*; do
    if [[ -f "$hook" ]]; then
      echo "  - $(basename "$hook")"
    fi
  done
}

# Create directory and cd into it
mkcd() {
  if [[ -z "$1" ]]; then
    echo "Usage: mkcd <directory>"
    return 1
  fi
  mkdir -p "$1" && cd "$1" || return 1
}

# Extract various archive formats
extract() {
  if [ -f "$1" ]; then
    case $1 in
      *.tar.bz2) tar xjf "$1" ;;
      *.tar.gz) tar xzf "$1" ;;
      *.bz2) bunzip2 "$1" ;;
      *.rar) unrar e "$1" ;;
      *.gz) gunzip "$1" ;;
      *.tar) tar xf "$1" ;;
      *.tbz2) tar xjf "$1" ;;
      *.tgz) tar xzf "$1" ;;
      *.zip) unzip "$1" ;;
      *) echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Kill processes by name
killp() {
  if [ -z "$1" ]; then
    echo "Usage: killp <process_name>"
    return 1
  fi
  ps aux | grep -i "$1" | grep -v grep | awk '{print $2}' | xargs kill -9 2> /dev/null
  echo "Killed processes matching: $1"
}

# Kill process on specific port
killport() {
  if [[ -n "$1" ]]; then
    lsof -ti:$1 | xargs kill -9
    echo "Killed processes on port $1"
  else
    echo "Usage: killport <port_number>"
  fi
}

# Backup file with timestamp
backup() {
  if [ -z "$1" ]; then
    echo "Usage: backup <filename>"
    return 1
  fi
  cp "$1" "$1.bak.$(date +%Y%m%d_%H%M%S)"
  echo "Backup created: $1.bak.$(date +%Y%m%d_%H%M%S)"
}

# Show directory sizes sorted
dirsize() {
  du -sh * | sort -hr
}

# Find files containing pattern
findgrep() {
  if [ $# -lt 2 ]; then
    echo "Usage: findgrep <pattern> <path>"
    return 1
  fi
  find "$2" -type f -exec grep -l "$1" {} \;
}

# Clone git repo and cd into it
gclone() {
  if [ -z "$1" ]; then
    echo "Usage: gclone <git_url>"
    return 1
  fi
  git clone "$1" && cd "$(basename "$1" .git)" || return 1
}

# Start simple HTTP server
serve() {
  local port=${1:-8000}
  echo "Starting web server on port $port..."
  echo "Open http://localhost:$port"
  python3 -m http.server "$port"
}

# Show available npm scripts
pjs() {
  if [[ -f package.json ]]; then
    echo "Available scripts:"
    jq -r '.scripts | to_entries[] | "  \(.key): \(.value)"' package.json
  else
    echo "No package.json found in current directory"
  fi
}

# Create new project
newproject() {
  if [[ -z "$1" ]]; then
    echo "Usage: newproject <project_name> [type]"
    echo "Types: node, php, dotnet, python"
    return 1
  fi

  mkdir -p "$1" && cd "$1" || return 1

  case "${2:-node}" in
    node)
      npm init -y
      echo "Node.js project created"
      ;;
    php)
      composer init --no-interaction
      echo "PHP project created"
      ;;
    dotnet)
      dotnet new console
      echo ".NET project created"
      ;;
    python)
      python3 -m venv venv
      echo "Python project with virtual environment created"
      echo "Run 'source venv/bin/activate' to activate"
      ;;
  esac
}

# PHP version switcher
if command -v ggrep > /dev/null 2>&1 && command -v brew > /dev/null 2>&1; then
  php_setup() {
    local installedPhpVersions=($(brew ls --versions 2> /dev/null | ggrep -E 'php(@.*)?\s' | ggrep -oP '(?<=\s)\d\.\d' | uniq | sort))
    for phpVersion in ${installedPhpVersions[*]}; do
      local value="{"
      for otherPhpVersion in ${installedPhpVersions[*]}; do
        if [ "${otherPhpVersion}" != "${phpVersion}" ]; then
          value="${value} brew unlink php@${otherPhpVersion};"
        fi
      done
      value="${value} brew link php@${phpVersion} --force --overwrite; } &> /dev/null && php -v"
      alias "${phpVersion}"="${value}"
    done
  }
  alias php-setup='php_setup'
fi

# Docker cleanup function
docker_purge() {
  echo "Cleaning up Docker system..."
  docker system prune -a
  docker volume prune
  docker image prune
}

# Battery status (works on macOS and Linux)
battery() {
  if [[ "$IS_MAC" == "true" ]]; then
    pmset -g batt | grep -Eo "[0-9]+%" | head -1
  elif [[ "$IS_LINUX" == "true" ]]; then
    if [[ -d "/sys/class/power_supply/BAT0" ]]; then
      local capacity=$(cat /sys/class/power_supply/BAT0/capacity 2> /dev/null)
      local status=$(cat /sys/class/power_supply/BAT0/status 2> /dev/null)
      echo "${capacity}% (${status})"
    elif command -v acpi > /dev/null 2>&1; then
      acpi -b | awk '{print $4}' | sed 's/,//'
    else
      echo "Battery information not available"
    fi
  else
    echo "Battery information not available on this system"
  fi
}

# Cheat sheet lookup from cheat.sh
cheat() {
  if [[ -z "$1" ]]; then
    echo "Usage: cheat <command>"
    echo "Example: cheat tar"
    echo "         cheat python/list comprehension"
    return 1
  fi
  curl -s "cheat.sh/$1" | less -R
}

# Quick cheat without pager
cheatq() {
  if [[ -z "$1" ]]; then
    echo "Usage: cheatq <command>"
    return 1
  fi
  curl -s "cheat.sh/$1?Q"
}

# Network debug tools
netdebug() {
  echo "\n🌐 Network Debug Information\n"
  echo "=== Public IP ==="
  curl -s ifconfig.me && echo ""
  echo "\n=== Local IPs ==="
  if [[ "$IS_MAC" == "true" ]]; then
    ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}'
  else
    ip addr | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}'
  fi
  echo "\n=== DNS Servers ==="
  if [[ "$IS_MAC" == "true" ]]; then
    scutil --dns | grep 'nameserver\[0\]' | awk '{print $3}'
  else
    cat /etc/resolv.conf | grep nameserver | awk '{print $2}'
  fi
  echo "\n=== Active Connections ==="
  echo "Established connections: $(netstat -an | grep -c ESTABLISHED)"
  echo "\n=== Listening Ports ==="
  lsof -i -P -n | grep LISTEN | head -10
}

# Check specific port in detail
portcheck() {
  if [[ -z "$1" ]]; then
    echo "Usage: portcheck <port_number>"
    return 1
  fi
  echo "Checking port $1..."
  lsof -i :$1 -P -n
}

# DNS lookup with details
dnscheck() {
  if [[ -z "$1" ]]; then
    echo "Usage: dnscheck <domain>"
    return 1
  fi
  echo "\n🔍 DNS Lookup for: $1\n"
  echo "=== A Records ==="
  dig +short A $1
  echo "\n=== AAAA Records (IPv6) ==="
  dig +short AAAA $1
  echo "\n=== MX Records ==="
  dig +short MX $1
  echo "\n=== NS Records ==="
  dig +short NS $1
}

# GitHub Actions cache management
ghcache() {
  if ! command -v gh > /dev/null 2>&1; then
    echo "Error: GitHub CLI (gh) is not installed"
    echo "Install from: https://cli.github.com/"
    return 1
  fi

  local repo=""
  local action="list"

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -r | --repo)
        repo="$2"
        shift 2
        ;;
      clear | delete | clean)
        action="clear"
        shift
        ;;
      list | ls)
        action="list"
        shift
        ;;
      *)
        echo "Unknown option: $1"
        echo "Usage: ghcache [list|clear] [-r|--repo owner/repo]"
        echo "  list   : List all caches (default)"
        echo "  clear  : Delete all caches"
        echo "  -r     : Specify repository (uses current if not provided)"
        return 1
        ;;
    esac
  done

  # Determine repository
  if [[ -z "$repo" ]]; then
    if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
      local remote_url=$(git config --get remote.origin.url)
      if [[ -n "$remote_url" ]]; then
        # Extract owner/repo from various URL formats
        repo=$(echo "$remote_url" | sed -E 's#.*[:/]([^/]+/[^/]+)(\.git)?$#\1#' | sed 's/\.git$//')
      fi
    fi

    if [[ -z "$repo" ]]; then
      echo "Error: Could not determine repository. Please specify with -r owner/repo"
      return 1
    fi
  fi

  echo "Repository: $repo"
  echo ""

  if [[ "$action" == "list" ]]; then
    echo "Fetching caches..."
    gh cache list --repo "$repo"
  elif [[ "$action" == "clear" ]]; then
    echo "Fetching caches to delete..."
    local cache_ids=$(gh cache list --repo "$repo" --json id --jq '.[].id')

    if [[ -z "$cache_ids" ]]; then
      echo "No caches found to delete."
      return 0
    fi

    local cache_count=$(echo "$cache_ids" | wc -l | tr -d ' ')
    echo "Found $cache_count cache(s) to delete."
    echo ""

    # Confirm deletion
    echo -n "Delete all caches? (y/N): "
    read -r confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
      echo "Aborted."
      return 0
    fi

    echo ""
    echo "Deleting caches..."
    local deleted=0
    local failed=0

    while IFS= read -r cache_id; do
      if gh cache delete "$cache_id" --repo "$repo" 2> /dev/null; then
        ((deleted++))
        echo "✓ Deleted cache ID: $cache_id"
      else
        ((failed++))
        echo "✗ Failed to delete cache ID: $cache_id"
      fi
    done <<< "$cache_ids"

    echo ""
    echo "Summary: $deleted deleted, $failed failed"
  fi
}

# FZF integrations
if command -v fzf > /dev/null 2>&1; then
  # Find and edit files
  fe() {
    local file
    file=$(fzf --preview 'bat --color=always {}' --preview-window=right:60%) && ${EDITOR:-code} "$file"
  }

  # Find and cd to directory
  fcd() {
    local dir
    dir=$(find . -type d -not -path '*/.*' | fzf) && cd "$dir" || return 1
  }
fi
