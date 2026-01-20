# ============================================
# Git-Specific Functions & Aliases
# ============================================

# Switch all repos in a directory to their default branch
git-default-all() {
  local target_dir="${1:-.}"
  local original_dir="$PWD"
  
  if [[ ! -d "$target_dir" ]]; then
    echo "Error: Directory '$target_dir' does not exist"
    return 1
  fi
  
  # Convert to absolute path
  target_dir=$(cd "$target_dir" && pwd)
  
  echo "Searching for git repositories in: $target_dir"
  
  # Find all .git directories (repos) and store in array
  local repos=()
  while IFS= read -r git_dir; do
    repos+=("$(dirname "$git_dir")")
  done < <(find "$target_dir" -maxdepth 3 -name ".git" -type d)
  
  local auto_yes=false
  
  for repo_dir in "${repos[@]}"; do
    echo "\n📁 Processing: $repo_dir"
    
    cd "$repo_dir" || continue
    
    # Get the default branch from remote
    local default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
    
    # If that fails, try common default branches
    if [[ -z "$default_branch" ]]; then
      if git show-ref --verify --quiet refs/heads/main; then
        default_branch="main"
      elif git show-ref --verify --quiet refs/heads/master; then
        default_branch="master"
      else
        echo "  ⚠️  Could not determine default branch, skipping"
        continue
      fi
    fi
    
    local current_branch=$(git branch --show-current)
    
    if [[ "$current_branch" == "$default_branch" ]]; then
      echo "  ✓ Already on $default_branch"
    else
      if [[ "$auto_yes" == true ]]; then
        echo "  🔀 Switching from '$current_branch' to '$default_branch'"
        git checkout "$default_branch" 2>&1 | sed 's/^/     /'
      else
        echo "  🔀 Switch from '$current_branch' to '$default_branch'?"
        echo -n "     [y/N/a(ll)] "
        read -r response
        
        case "$response" in
          [yY]|[yY][eE][sS])
            git checkout "$default_branch" 2>&1 | sed 's/^/     /'
            ;;
          [aA]|[aA][lL][lL])
            echo "  Switching to auto-yes mode..."
            git checkout "$default_branch" 2>&1 | sed 's/^/     /'
            auto_yes=true
            ;;
          *)
            echo "  ⏭️  Skipped"
            ;;
        esac
      fi
    fi
  done
  
  cd "$original_dir"
  echo "\n✅ Done!"
}

# Pull latest changes for all repos in a directory
git-pull-all() {
  local target_dir="${1:-.}"
  
  if [[ ! -d "$target_dir" ]]; then
    echo "Error: Directory '$target_dir' does not exist"
    return 1
  fi
  
  echo "Pulling latest changes for all repos in: $target_dir"
  
  find "$target_dir" -maxdepth 3 -name ".git" -type d | while read -r git_dir; do
    local repo_dir=$(dirname "$git_dir")
    echo "\n📁 $repo_dir"
    
    cd "$repo_dir" || continue
    git pull 2>&1 | sed 's/^/   /'
  done
  
  cd "$OLDPWD"
  echo "\n✅ Done!"
}

# Show status of all repos in a directory
git-status-all() {
  local target_dir="${1:-.}"
  
  if [[ ! -d "$target_dir" ]]; then
    echo "Error: Directory '$target_dir' does not exist"
    return 1
  fi
  
  echo "Checking status for all repos in: $target_dir\n"
  
  find "$target_dir" -maxdepth 3 -name ".git" -type d | while read -r git_dir; do
    local repo_dir=$(dirname "$git_dir")
    cd "$repo_dir" || continue
    
    local repo_name=$(basename "$repo_dir")
    local branch=$(git branch --show-current)
    local status=$(git status --porcelain)
    local unpushed=$(git log @{u}.. --oneline 2>/dev/null | wc -l | tr -d ' ')
    
    if [[ -n "$status" ]] || [[ "$unpushed" -gt 0 ]]; then
      echo "📁 $repo_name [$branch]"
      if [[ -n "$status" ]]; then
        echo "   ⚠️  Uncommitted changes"
      fi
      if [[ "$unpushed" -gt 0 ]]; then
        echo "   ⬆️  $unpushed unpushed commits"
      fi
      echo ""
    fi
  done
  
  cd "$OLDPWD"
}
