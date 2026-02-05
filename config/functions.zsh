# ============================================
# Custom Utility Functions
# ============================================

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
      *.tar.bz2)   tar xjf "$1"     ;;
      *.tar.gz)    tar xzf "$1"     ;;
      *.bz2)       bunzip2 "$1"     ;;
      *.rar)       unrar e "$1"     ;;
      *.gz)        gunzip "$1"      ;;
      *.tar)       tar xf "$1"      ;;
      *.tbz2)      tar xjf "$1"     ;;
      *.tgz)       tar xzf "$1"     ;;
      *.zip)       unzip "$1"       ;;
      *)           echo "'$1' cannot be extracted via extract()" ;;
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
  ps aux | grep -i "$1" | grep -v grep | awk '{print $2}' | xargs kill -9 2>/dev/null
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
if command -v ggrep >/dev/null 2>&1 && command -v brew >/dev/null 2>&1; then
  php_setup() {
    local installedPhpVersions=($(brew ls --versions 2>/dev/null | ggrep -E 'php(@.*)?\s' | ggrep -oP '(?<=\s)\d\.\d' | uniq | sort))
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

# FZF integrations
if command -v fzf >/dev/null 2>&1; then
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
