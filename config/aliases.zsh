# ============================================
# Aliases
# ============================================

# Safety aliases - prompt before overwriting
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# General system
if [[ "$IS_MAC" == "true" ]]; then
  alias update='brew update && brew upgrade && brew cleanup'
elif [[ "$IS_LINUX" == "true" ]]; then
  alias update='sudo apt update && sudo apt upgrade -y && brew update && brew upgrade'
fi

# Modern ls alternatives (eza)
alias ls='eza --color=auto --group-directories-first'
alias ll='eza -alF --color=auto --group-directories-first --git'
alias la='eza -a --color=auto --group-directories-first'
alias l='eza -F --color=auto --group-directories-first'
alias tree='eza --tree --color=auto'
alias lls='/bin/ls -alF' # Traditional fallback
alias lla='/bin/ls -A'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Modern alternatives
alias cat='bat --style=auto'
alias ff='fd'
alias grep='rg'

# Utility
alias c='clear'
alias h='history'
alias reload='source ~/.zshrc'
alias src='source ~/.zshrc'
alias dcuf='docker compose up -d --force-recreate'
alias zshconfig='nano ~/.zshrc'
alias starshipconfig='nano ~/.config/starship.toml'
alias zshrepo='code "${ZSHRC_DIR:-$HOME/Git/zshrc-profile}"'

# JSON/YAML formatters and validators
alias jsonf='python3 -m json.tool'
alias jsonp='jq .'
alias jsonc='jq -c .'
alias yamlf='python3 -c "import sys, yaml, json; print(yaml.dump(json.loads(sys.stdin.read()), default_flow_style=False))"'
alias yamltojson='python3 -c "import sys, yaml, json; print(json.dumps(yaml.safe_load(sys.stdin.read()), indent=2))"'
alias jsontoyaml='python3 -c "import sys, yaml, json; print(yaml.dump(json.loads(sys.stdin.read()), default_flow_style=False))"'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gp='git push'
alias gpom='git push origin main'
alias gl='git pull'
alias glg='git log --stat'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias glog='git log --oneline --decorate --graph'
alias grh='git reset --hard'
alias grm='git rebase main'

# Git stash shortcuts
alias gst='git stash'
alias gsta='git stash apply'
alias gstl='git-stash-list'
alias gsts='git-stash-save'
alias gstsh='git-stash-show'
alias gstd='git-stash-drop'
alias gstp='git stash pop'

# Git tools
alias gup='$BREW_PREFIX/bin/gitup' # gitup CLI (brew)
alias gitup-gui='open -a GitUp'    # GitUp GUI app

# NVM
alias nvml='nvm list'
alias nvmls='nvm list-remote'
alias nvmu='nvm use'
alias nvmi='nvm install'
alias nvmun='nvm uninstall'
alias nvms='nvm alias default'
alias nvml16='nvm use 16'
alias nvml18='nvm use 18'
alias nvml20='nvm use 20'

# Node/NPM
alias ni='npm install'
alias nid='npm install --save-dev'
alias nig='npm install -g'
alias ns='npm start'
alias nt='npm test'
alias nr='npm run'
alias nrb='npm run build'
alias nrd='npm run dev'

# Yarn
alias yi='yarn install'
alias ys='yarn start'
alias yt='yarn test'
alias ya='yarn add'
alias yad='yarn add --dev'

# PHP & Composer
alias composer="php /usr/local/bin/composer.phar"
alias phpserve='php -S localhost:8000'
alias ci='composer install'
alias cu='composer update'
alias cr='composer require'
alias cda='composer dump-autoload'

# Docker
alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias dpa='docker ps -a'
alias di='docker images'
alias dcu='docker compose up'
alias dcud='docker compose up -d'
alias dcd='docker compose down'
alias dce='docker compose exec'
alias dcl='docker compose logs -f'
alias dcr='docker compose restart'
alias dsp='docker system prune -a'
alias dstop='docker stop $(docker ps -q)'
alias dclean='docker system prune -af'
alias dex='docker exec -it'
alias dlogs='docker logs -f'
alias dins='docker inspect'
alias dnet='docker network ls'
alias dvol='docker volume ls'
alias qcc="pushd \$HOME/git/tools; docker compose exec memcached bash -c \"echo flush_all > /dev/tcp/127.0.0.1/11211\"; popd"

# MySQL (only if brew is available)
if command -v brew &> /dev/null; then
  alias mysqlstart='brew services start mysql'
  alias mysqlstop='brew services stop mysql'
  alias mysqlrestart='brew services restart mysql'
fi

# Tilt
alias tup='tilt up'
alias tdown='tilt down'
alias ts='tilt status'

# Starship
alias starship-update='starship update'
alias starship-config='starship config'
alias starship-explain='starship explain'

# Development shortcuts
alias weather='curl wttr.in'
alias myip='curl ifconfig.me'
alias ports='lsof -i -P -n | grep LISTEN'
alias diskusage='du -sh * | sort -hr'
alias processes='ps aux | grep -v grep | grep'

# GitHub CLI
alias ghs='gh status'
alias ghr='gh repo'
alias ghi='gh issue'
alias ghpr='gh pr'
alias ghw='gh workflow'
alias ghrc='gh repo create'
alias ghrcl='gh repo clone'
alias ghrv='gh repo view'
alias ghrf='gh repo fork'
alias ghprl='gh pr list'
alias ghprc='gh pr create'
alias ghprco='gh pr checkout'
alias ghprm='gh pr merge'
alias ghprs='gh pr status'
alias ghil='gh issue list'
alias ghic='gh issue create'
alias ghb='gh browse'
alias ghquick='gh pr create --draft'
alias ghmerge='gh pr merge --merge'
alias ghsquash='gh pr merge --squash'

# .NET
alias dn='dotnet'
alias dnr='dotnet run'
alias dnb='dotnet build'
alias dnt='dotnet test'
alias dnrst='dotnet restore'
alias dnclean='dotnet clean'
alias dnwatch='dotnet watch run'
alias dnnew='dotnet new'
alias dnadd='dotnet add'
alias dnremove='dotnet remove'

# AWS CDK
alias cdks='cdk synth'
alias cdkd='cdk deploy'
alias cdkdest='cdk destroy'
alias cdkls='cdk ls'
alias cdkdiff='cdk diff'
alias cdkboot='cdk bootstrap'

# Lazy tools
alias lzd='lazydocker'
alias lzk='lazykube'
alias lzg='lazygit'

# Project shortcuts
alias www='cd ~/www'
alias desktop='cd ~/Desktop'
alias downloads='cd ~/Downloads'
alias documents='cd ~/Documents'

# Android Studio (OS-specific)
if [[ "$IS_LINUX" == "true" ]] && [[ -f "/snap/bin/android-studio" ]]; then
  alias studio="/snap/bin/android-studio > /dev/null 2>&1 &"
  alias studio.="/snap/bin/android-studio . > /dev/null 2>&1 &"
elif [[ "$IS_MAC" == "true" ]] && [[ -d "/Applications/Android Studio.app" ]]; then
  alias studio="open -a 'Android Studio'"
  alias studio.="open -a 'Android Studio' ."
fi

# Create www directory if it doesn't exist
[ ! -d "$HOME/www" ] && mkdir -p "$HOME/www"
