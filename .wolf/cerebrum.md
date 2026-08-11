# Cerebrum

> OpenWolf's learning memory. Updated automatically as the AI learns from interactions.
> Do not edit manually unless correcting an error.
> Last updated: 2026-04-29

## User Preferences

<!-- How the user likes things done. Code style, tools, patterns, communication. -->

## Key Learnings

- **Project:** zshrc-profile
- **Description:** A portable, modular ZSH configuration that works seamlessly across macOS and Linux (WSL2)

## Do-Not-Repeat

<!-- Mistakes made and corrected. Each entry prevents the same mistake recurring. -->
<!-- Format: [YYYY-MM-DD] Description of what went wrong and what to do instead. -->

- [2026-08-11] Added Android SDK/JAVA_HOME/Flutter exports to config/linux.zsh without first checking config/exports.zsh, which already had an OS-guarded (IS_LINUX/IS_MAC) ANDROID_HOME block and a commented-out JAVA_HOME line. Result: duplicated exports. Fix: before adding any new export/PATH entry, grep config/exports.zsh and the relevant os-specific file (linux.zsh/macos.zsh) for existing definitions of that var first; prefer extending exports.zsh's existing OS-guard blocks over adding new blocks to the per-OS files.

## Decision Log

<!-- Significant technical decisions with rationale. Why X was chosen over Y. -->
