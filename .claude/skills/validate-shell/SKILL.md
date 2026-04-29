---
name: validate-shell
description: Run ShellCheck and Prettier format check on all ZSH/shell files
disable-model-invocation: true
---

Run the full validation suite:

```bash
cd "$CLAUDE_PROJECT_DIR" && pnpm run check
```

Report any ShellCheck errors or formatting issues found.
