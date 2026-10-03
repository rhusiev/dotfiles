# Findings

Non-obvious behaviour of tools these dotfiles depend on

- Alacritty loads `general.import` files before the importing file, so the main config overrides its imports. A missing import is skipped silently
- Git overwrites ignored untracked files on checkout and merge without asking. Before tracking a path that a machine already has as an ignored file (e.g. `config/claude/settings.json`), merge its contents first
