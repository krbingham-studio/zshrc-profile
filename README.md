# 🚀 ZSH Configuration Profile

A portable, modular ZSH configuration that works seamlessly across macOS and Linux (WSL2). Keep your shell configuration in sync across all your development machines with version control.

## ✨ Features

- **🎨 Starship Prompt** - Beautiful, fast, and customizable prompt
- **⚡ Performance Optimized** - Smart caching and lazy loading
- **🔧 Modular Configuration** - Organized into separate, maintainable files
- **🌐 Cross-Platform** - Works on both macOS and Linux/WSL2
- **📦 Modern CLI Tools** - Includes aliases for `eza`, `bat`, `ripgrep`, `fd`, and more
- **🔐 Secrets Management** - Keep API keys and tokens separate from version control
- **🎯 Smart Completions** - Enhanced autocomplete with caching
- **🔑 Key Bindings** - Intuitive keyboard shortcuts for navigation

## 📁 Structure

```
zshrc-profile/
├── .zshrc              # Main configuration file
├── .zshrc.system       # Symlink -> ~/.zshrc (local, not committed)
├── .zsh_secrets.system # Symlink -> ~/.zsh_secrets (local, not committed)
├── config/             # Modular configuration files
│   ├── aliases.zsh     # Command aliases and shortcuts
│   ├── exports.zsh     # Environment variables and PATH
│   ├── functions.zsh   # Custom shell functions
│   ├── git.zsh         # Git-specific aliases and functions
│   ├── macos.zsh       # macOS-specific configuration (work stuff)
│   └── linux.zsh       # Linux/WSL2-specific configuration
└── hooks/              # Global git hooks
    └── prepare-commit-msg  # Auto-add ticket numbers to commits
```

## 🛠️ Prerequisites

### Required Tools

1. **Homebrew** (package manager)
   - macOS: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
   - Linux: See [brew.sh](https://brew.sh/)

2. **Starship** (prompt)
   ```bash
   brew install starship
   ```

3. **Modern CLI Tools**
   ```bash
   brew install eza bat ripgrep fd zoxide
   ```

### Optional Tools

```bash
# Enhanced ZSH experience
brew install zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search

# Additional utilities
brew install nvm git-delta fzf
```

## 📥 Installation

### First-Time Setup

1. **Clone this repository**
   ```bash
   git clone <your-repo-url> ~/Git/zshrc-profile
   ```

2. **Backup your existing `.zshrc`** (if you have one)
   ```bash
   mv ~/.zshrc ~/.zshrc.backup
   ```

3. **Create a minimal local `.zshrc`**
   ```bash
   cat > ~/.zshrc << 'EOF'
    # ============================================
    # ZSH Configuration - Git Repo Sourced
    # ============================================
    # This file sources the main configuration from the Git repository
    # allowing the same config to be used across multiple machines.
    #
    # Git Repository: ~/Git/zshrc-profile
    # To update: cd ~/Git/zshrc-profile && git pull
    # ============================================
    
    # Source the main configuration from Git repo
    if [[ -f "$HOME/Git/zshrc-profile/.zshrc" ]]; then
        source "$HOME/Git/zshrc-profile/.zshrc"
    else
        echo "⚠️  Warning: zshrc Git repository not found at ~/Git/zshrc-profile"
        echo "Clone it with: git clone <your-repo-url> ~/Git/zshrc-profile"
    fi
    EOF
   ```

4. **Create a `.zsh_secrets` file for private data** (optional)
   ```bash
   touch ~/.zsh_secrets
   chmod 600 ~/.zsh_secrets
   ```
   
   Add your API keys, tokens, and other secrets here:
   ```bash
   # Example contents of ~/.zsh_secrets
   export GITHUB_TOKEN="your_token_here"
   export OPENAI_API_KEY="your_key_here"
   ```

5. **Create local symlinks for IDE/editor access** (optional)

   Symlink your local dotfiles into the repo so you can edit them directly from this directory:
   ```bash
   ln -s ~/.zshrc ~/Git/zshrc-profile/.zshrc.system
   ln -s ~/.zsh_secrets ~/Git/zshrc-profile/.zsh_secrets.system
   ```

   These are ignored by git (see `.gitignore`) — they're just convenience pointers so your editor can open the live files from within the repo.

6. **Reload your shell**
   ```bash
   source ~/.zshrc
   ```

6. **Setup global git hooks** (optional but recommended)
   ```bash
   setup_git_hooks
   ```
   
   This will:
   - Configure Git to use `~/Git/zshrc-profile/hooks` as the global hooks directory
   - Make all hooks in the repo executable
   - Keep hooks version-controlled and automatically updated with `git pull`

## 🎣 Global Git Hooks

This repository includes global git hooks that work across all your repositories.

### Available Hooks

#### `prepare-commit-msg`
Automatically extracts the ticket number from your branch name and adds it to your conventional commit scope.

**Example:**
- Branch: `FORGEHELM-9-realm-aware-api-context`
- Commit: `feat: add realm context`
- Result: `feat(FORGEHELM-9): add realm context`

**How it works:**
- Detects branches with format: `TICKET-123-description`
- Only modifies commits using conventional commit format (`feat:`, `fix:`, `chore:`, etc.)
- Won't override existing scopes or tickets already in the message
- Works with `git commit -m "message"` and interactive commits

### Managing Hooks

**Setup hooks:**
```bash
setup_git_hooks
```

This configures Git globally to use hooks directly from `~/Git/zshrc-profile/hooks`.

**Update hooks:**
Simply pull the latest changes - hooks are used directly from this repo:
```bash
cd ~/Git/zshrc-profile
git pull
```

**Disable for a specific repo:**
```bash
cd your-repo
git config --local core.hooksPath .git/hooks
```

**Re-enable global hooks:**
```bash
cd your-repo
git config --unset --local core.hooksPath
```

## 🔄 Using Across Multiple Machines

### On Additional Machines

1. Clone the repo:
   ```bash
   git clone <your-repo-url> ~/Git/zshrc-profile
   ```

2. Create the same minimal `~/.zshrc` (step 3 from above)

3. Reload: `source ~/.zshrc`

### Keeping Synchronized

On any machine, pull the latest changes:
```bash
cd ~/Git/zshrc-profile
git pull
source ~/.zshrc
```

To push local changes:
```bash
cd ~/Git/zshrc-profile
git add .
git commit -m "Update configuration"
git push
```

## 📝 Customization

### Adding Aliases

Edit [config/aliases.zsh](config/aliases.zsh):
```bash
alias myalias='my command here'
```

### Adding Environment Variables

Edit [config/exports.zsh](config/exports.zsh):
```bash
export MY_VAR="value"
```

### Adding Functions

Edit [config/functions.zsh](config/functions.zsh):
```bash
myfunction() {
  # Your code here
}
```

### Machine-Specific Configuration

For configuration that should NOT be synced (like local paths or secrets):

1. Keep it in `~/.zsh_secrets` (already sourced by the main config)
2. Or add conditional logic in the main config:
   ```bash
   if [[ "$HOST" == "my-work-laptop" ]]; then
       # Work-specific config
   fi
   ```

### `GIT_HOME` — Git Repositories Root

The `repo` function searches for git repositories under `~/Git` by default. If your repos live elsewhere, set `GIT_HOME` in `~/.zsh_secrets` or your local config:

```bash
export GIT_HOME="$HOME/Projects"
```

Usage:
```bash
repo            # fzf fuzzy picker across all repos
repo zshrc      # jump directly if only one match, otherwise filter in fzf
```

## 🎯 Included Features

### Modern CLI Aliases

- `ls`, `ll`, `la`, `l` - Enhanced directory listings with `eza`
- `cat` - Syntax highlighting with `bat`
- `grep` - Fast searching with `ripgrep`
- `ff` - Fast file finding with `fd`
- `z` - Smart directory jumping with `zoxide`

### Git Functions

- `git-default-all` - Switch all repos in a directory to their default branch
- Plus many more git helpers and aliases

### Utility Functions

- `repo` - Jump to any git repo under `~/Git` by name (fzf fuzzy picker or exact match)
- `mkcd` - Create directory and cd into it
- `extract` - Extract any archive format
- `killp` - Kill processes by name
- And many more...

### Key Bindings

- `Ctrl+→` / `Ctrl+←` - Move word by word
- `Ctrl+P` / `Ctrl+N` - History search
- `↑` / `↓` - Substring history search
- `Home` / `End` - Jump to line start/end

## 🔒 Security

- **Never commit secrets** - Use `~/.zsh_secrets` for API keys and tokens
- This repository should be **private** if it contains any machine-specific paths or identifiers
- Review before committing to ensure no sensitive data is included

## 🧪 Development

This project uses PNPM for package management and includes linting and formatting tools to ensure code quality.

### Prerequisites

Install PNPM if you haven't already:
```bash
# Using Homebrew
brew install pnpm

# Or using npm
npm install -g pnpm
```

### Setup

Install development dependencies:
```bash
pnpm install
```

### Available Commands

- **Lint**: Check for shell script issues using ShellCheck
  ```bash
  pnpm run lint
  ```

- **Format**: Auto-format shell scripts using Prettier
  ```bash
  pnpm run format
  ```

- **Format Check**: Check if files are properly formatted (useful in CI)
  ```bash
  pnpm run format:check
  ```

- **Check All**: Run both linting and format checking
  ```bash
  pnpm run check
  ```

### Tools Used

- **[ShellCheck](https://www.shellcheck.net/)** - Static analysis tool for shell scripts
- **[Prettier](https://prettier.io/)** with **[prettier-plugin-sh](https://github.com/un-ts/prettier/tree/master/packages/sh)** - Code formatter for shell scripts

### GitHub Actions

This repository includes a GitHub Actions workflow that automatically:
- Runs ShellCheck on all `.zsh` files
- Verifies formatting with Prettier
- Runs on every push to `main` and on all pull requests

The workflow configuration can be found in [.github/workflows/lint.yml](.github/workflows/lint.yml).

### Configuration Files

- [.shellcheckrc](.shellcheckrc) - ShellCheck configuration
- [.prettierrc](.prettierrc) - Prettier configuration
- [.prettierignore](.prettierignore) - Files to ignore when formatting
- [.editorconfig](.editorconfig) - Editor configuration for consistent formatting
- [package.json](package.json) - Node.js package configuration with scripts

## 🐛 Troubleshooting

### Configuration not loading

Check that the path in your local `~/.zshrc` matches where you cloned the repo:
```bash
cat ~/.zshrc | grep source
```

### Missing commands

Ensure all dependencies are installed:
```bash
brew install starship eza bat ripgrep fd zoxide
```

### Permission issues

Make sure the config files are readable:
```bash
chmod 644 ~/Git/zshrc-profile/.zshrc
chmod 644 ~/Git/zshrc-profile/config/*.zsh
```

### Local .zshrc
Update your local .zshrc to

```bash
# ============================================
# ZSH Configuration - Git Repo Sourced
# ============================================
# This file sources the main configuration from the Git repository
# allowing the same config to be used across multiple machines.
#
# Git Repository: ~/Git/zshrc-profile
# To update: cd ~/Git/zshrc-profile && git pull
# ============================================

# Source the main configuration from Git repo
if [[ -f "$HOME/Git/zshrc-profile/.zshrc" ]]; then
    source "$HOME/Git/zshrc-profile/.zshrc"
else
    echo "⚠️  Warning: zshrc Git repository not found at ~/Git/zshrc-profile"
    echo "Clone it with: git clone <your-repo-url> ~/Git/zshrc-profile"
fi
```

## 📚 Learn More

- [Starship Prompt](https://starship.rs/)
- [Zsh Documentation](https://zsh.sourceforge.io/Doc/)
- [Modern Unix Tools](https://github.com/ibraheemdev/modern-unix)

## 📄 License

This is a personal configuration repository. Feel free to fork and customize for your own use.

---

**Tip**: Run `zshconfig` to quickly edit your configuration, or `starshipconfig` to customize your prompt!
