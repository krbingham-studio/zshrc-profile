---
name: new-alias
description: Conventions for adding new ZSH aliases to this repo
user-invocable: false
---

When adding a new alias:
1. Place it in `config/aliases.zsh`, grouped by topic
2. Use `alias name='command'` syntax (single quotes)
3. Add a comment above non-obvious aliases explaining what they do
4. Keep names short but recognizable — prefer `dcuf` over `docker-compose-up-force`
5. After editing, run `pnpm prettier --write config/aliases.zsh`
