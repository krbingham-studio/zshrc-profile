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

# Find and delete all dist folders in a directory
cleandist() {
  local search_dir="${1:-.}"

  if [[ ! -d "$search_dir" ]]; then
    echo "Error: '$search_dir' is not a valid directory"
    return 1
  fi

  local dist_dirs
  dist_dirs=$(find "$search_dir" -type d -name "node_modules" -prune -o -type d -name "dist" -print 2> /dev/null)

  if [[ -z "$dist_dirs" ]]; then
    echo "No dist folders found in $search_dir"
    return 0
  fi

  local count
  count=$(echo "$dist_dirs" | wc -l | tr -d ' ')
  echo "Found $count dist folder(s):"
  echo "  ${dist_dirs//$'\n'/$'\n'  }"
  echo ""
  echo -n "Delete all? (y/N): "
  read -r confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Aborted."
    return 0
  fi

  echo "$dist_dirs" | while IFS= read -r dir; do
    if rm -rf "$dir"; then
      echo "✓ Deleted: $dir"
    else
      echo "✗ Failed to delete: $dir"
    fi
  done
}

# Navigate to a repo by name within $GIT_HOME (default: ~/Git)
repo() {
  local git_home="${GIT_HOME:-$HOME/Git}"

  if [[ ! -d "$git_home" ]]; then
    echo "repo: directory not found: $git_home"
    return 1
  fi

  local repos
  repos=$(find "$git_home" -maxdepth 5 -name "node_modules" -prune -o -name ".git" -type d -print 2> /dev/null | sed 's|/.git$||')

  if command -v fzf > /dev/null 2>&1; then
    local target
    target=$(echo "$repos" | sed "s|$git_home/||" | fzf --query="${1:-}" --select-1 --exit-0)
    [[ -n "$target" ]] && cd "$git_home/$target" || return 1
  else
    if [[ -z "$1" ]]; then
      echo "$repos" | sed "s|$git_home/||"
      return 0
    fi
    local target
    target=$(echo "$repos" | grep -i "/$1$" | head -1)
    if [[ -z "$target" ]]; then
      target=$(echo "$repos" | grep -i "$1" | head -1)
    fi
    if [[ -n "$target" ]]; then
      cd "$target" || return 1
    else
      echo "repo: no match for '$1'"
      return 1
    fi
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

# ─── AI Tool Sync ─────────────────────────────────────────────────────────────
# Push AI tool usage snapshots to your Forgehelm dashboard.
# Supports: claude-code, github-copilot.
# Add new tools by implementing _ai_sync_collect_<tool-name>() below.
#
# Usage:
#   ai-sync                      # Claude Code only (default)
#   ai-sync --all                # All detected tools
#   ai-sync --tool github-copilot
#
# Requires FORGEHELM_API_TOKEN set in ~/.zsh_secrets.
# Generate a token at /admin/tokens in Forgehelm Studio.
# ─────────────────────────────────────────────────────────────────────────────
ai-sync() {
  local api_url="${FORGEHELM_API_URL:-http://localhost:4000/graphql}"
  local api_token="${FORGEHELM_API_TOKEN:-}"
  local tools=("claude-code")

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --all)
        tools=("claude-code" "github-copilot")
        shift
        ;;
      --tool)
        tools=("$2")
        shift 2
        ;;
      *) shift ;;
    esac
  done

  if [[ -z "$api_token" ]]; then
    echo "[ai-sync] Error: FORGEHELM_API_TOKEN is not set."
    echo "  1. Generate a token at /admin/tokens in Forgehelm Studio."
    echo "  2. Add to ~/.zsh_secrets: export FORGEHELM_API_TOKEN=<token>"
    return 1
  fi

  local mutation='mutation CreateAiUsageSnapshot($source: String!, $claudeVersion: String, $sessionId: String, $data: Json!) { createAiUsageSnapshot(source: $source, claudeVersion: $claudeVersion, sessionId: $sessionId, data: $data) { id capturedAt } }'

  for tool in "${tools[@]}"; do
    local source="" claude_version="" session_id="" tool_data=""

    case "$tool" in
      claude-code)
        source="claude-code"
        claude_version="${CLAUDE_CODE_VERSION:-}"
        session_id="${CLAUDE_CODE_SESSION_ID:-}"
        tool_data=$(_ai_sync_collect_claude_code 2> /dev/null)
        ;;
      github-copilot)
        if ! command -v gh > /dev/null 2>&1; then
          echo "[ai-sync] Skipping github-copilot: gh CLI not installed"
          continue
        fi
        source="github-copilot"
        tool_data=$(_ai_sync_collect_github_copilot 2> /dev/null)
        ;;
      *)
        echo "[ai-sync] Unknown tool: $tool (supported: claude-code, github-copilot)"
        continue
        ;;
    esac

    if [[ -z "$tool_data" ]]; then
      echo "[ai-sync] ✗ $tool: failed to collect data"
      continue
    fi

    echo "[ai-sync] Syncing $tool..."

    local payload
    payload=$(jq -n \
      --arg query "$mutation" \
      --arg src "$source" \
      --arg cv "$claude_version" \
      --arg sid "$session_id" \
      --argjson data "$tool_data" \
      '{query: $query, variables: {
        source: $src,
        claudeVersion: (if $cv == "" then null else $cv end),
        sessionId: (if $sid == "" then null else $sid end),
        data: $data
      }}' 2> /dev/null)

    if [[ -z "$payload" ]]; then
      echo "[ai-sync] ✗ $tool: failed to build request payload"
      continue
    fi

    local response
    response=$(curl -sf -X POST "$api_url" \
      -H "Content-Type: application/json" \
      -H "Authorization: Bearer $api_token" \
      -d "$payload" 2> /dev/null)

    if echo "$response" | jq -e '.data.createAiUsageSnapshot.id' > /dev/null 2>&1; then
      local snap_id
      snap_id=$(echo "$response" | jq -r '.data.createAiUsageSnapshot.id')
      echo "[ai-sync] ✓ $tool snapshot saved (id: ${snap_id:0:8}...)"
    else
      local err
      err=$(echo "$response" | jq -r '.errors[0].message // "no response from server"' 2> /dev/null)
      echo "[ai-sync] ✗ $tool failed: $err"
    fi
  done
}

# ── Internal: collect Claude Code data ────────────────────────────────────────
_ai_sync_collect_claude_code() {
  local account_uuid="${CLAUDE_CODE_ACCOUNT_UUID:-}"
  local org_uuid="${CLAUDE_CODE_ORGANIZATION_UUID:-}"
  local first_start="" enabled_flags=0 skills_count=0 project_count=0
  local session_cwd="" session_started_at="" session_kind=""

  if [[ -f "$HOME/.claude.json" ]]; then
    enabled_flags=$(jq '[.cachedGrowthBookFeatures | to_entries[] | select(.value == true)] | length' \
      "$HOME/.claude.json" 2> /dev/null || echo 0)
    first_start=$(jq -r '.firstStartTime // ""' "$HOME/.claude.json" 2> /dev/null)
  fi

  local sessions_dir="$HOME/.claude/sessions"
  if [[ -d "$sessions_dir" ]]; then
    local session_file
    # shellcheck disable=SC2012
    session_file=$(ls -t "$sessions_dir"/*.json 2> /dev/null | head -1)
    if [[ -n "$session_file" ]]; then
      session_cwd=$(jq -r '.cwd // ""' "$session_file" 2> /dev/null)
      session_started_at=$(jq -r '.startedAt // ""' "$session_file" 2> /dev/null)
      session_kind=$(jq -r '.kind // ""' "$session_file" 2> /dev/null)
    fi
  fi

  [[ -d "$HOME/.claude/skills" ]] \
    && skills_count=$(find "$HOME/.claude/skills" -mindepth 1 -maxdepth 1 -type d 2> /dev/null | wc -l | tr -d ' ')
  [[ -d "$HOME/.claude/projects" ]] \
    && project_count=$(find "$HOME/.claude/projects" -mindepth 1 -maxdepth 1 -type d 2> /dev/null | wc -l | tr -d ' ')

  jq -n \
    --arg acct "$account_uuid" \
    --arg org "$org_uuid" \
    --arg firstStart "$first_start" \
    --argjson flags "$enabled_flags" \
    --argjson skills "$skills_count" \
    --argjson projects "$project_count" \
    --arg cwd "$session_cwd" \
    --arg startedAt "$session_started_at" \
    --arg kind "$session_kind" \
    '{accountUuid: $acct, orgUuid: $org, firstStartTime: $firstStart,
      enabledFlags: $flags, skillsCount: $skills, projectCount: $projects,
      session: {cwd: $cwd, startedAt: $startedAt, kind: $kind}}'
}

# ── Internal: collect GitHub Copilot data ────────────────────────────────────
# Extend this function as Copilot's CLI surface grows.
_ai_sync_collect_github_copilot() {
  local gh_version copilot_version auth_user rate_remaining=""

  gh_version=$(gh --version 2> /dev/null | head -1 | awk '{print $3}')

  copilot_version=""
  if gh extension list 2> /dev/null | grep -q "copilot"; then
    copilot_version=$(gh copilot --version 2> /dev/null | head -1 || echo "")
  fi

  auth_user=$(gh api /user --jq '.login' 2> /dev/null || echo "")

  if [[ -n "$auth_user" ]]; then
    rate_remaining=$(gh api /rate_limit --jq '.rate.remaining' 2> /dev/null || echo "")
  fi

  jq -n \
    --arg ghVersion "$gh_version" \
    --arg copilotVersion "$copilot_version" \
    --arg authUser "$auth_user" \
    --arg rateRemaining "$rate_remaining" \
    '{ghCliVersion: $ghVersion, copilotExtensionVersion: $copilotVersion,
      authenticatedUser: $authUser, apiRateRemaining: $rateRemaining}'
}

# Launch the AI Tools Dashboard (Vite + Express) from anywhere
ai-dashboard() {
  local dashboard_dir="${ZSHRC_DIR:-$HOME/Git/zshrc-profile}/dashboard"

  if [[ ! -d "$dashboard_dir" ]]; then
    echo "ai-dashboard: dashboard not found at $dashboard_dir" >&2
    return 1
  fi

  echo "Starting AI Dashboard → http://localhost:5173"
  (cd "$dashboard_dir" && pnpm dev)
}

# Edit hosts file with vi and sudo, using correct path for OS
edithosts() {
  local hosts_file=""
  if [[ "$IS_MAC" == "true" ]]; then
    hosts_file="/etc/hosts"
  elif [[ "$IS_LINUX" == "true" ]]; then
    hosts_file="/etc/hosts"
  else
    echo "Unsupported OS for editing hosts file."
    return 1
  fi
  echo "Editing $hosts_file with sudo and vi..."
  sudo nano "$hosts_file"
}
