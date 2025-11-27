# AGENTS.md

This dotfiles repository contains configuration files for various development tools. This guide helps AI agents understand the project structure and conventions.

## Project Structure

- **`nvim/`** - Neovim configuration (Lua-based)
  - `init.lua` - Entry point, sets up lazy.nvim
  - `lua/core/` - Core settings (options, keymaps, autocmds)
  - `lua/plugins/` - Plugin configurations
- **`vim/`** - Vim configuration (vim-plug based)
- **`zsh/`** - Zsh configuration (zshrc, aliases, functions, theme)
- **`tmux/`** - Tmux configuration
- **`hammerspoon/`** - macOS automation scripts (macOS only)
- **`git/`** - Git configuration
- **`wezterm/`** - WezTerm terminal configuration
- **`ghostty/`** - Ghostty terminal configuration
- **`lsd/`** - lsd (ls alternative) configuration
- **`bin/`** - Utility scripts

## Key Conventions

1. **Neovim plugins**: Managed by lazy.nvim and stored in `~/.local/share/nvim/lazy/`. Always check plugin code when configuring or using plugin APIs.

2. **Symlink setup**: The `setup.sh` script creates symlinks from this repository to standard config locations (e.g., `nvim/` → `~/.config/nvim`).

3. **Local overrides**: Some tools support local config files (e.g., `hammerspoon/local.lua`, `*.local` files) which are gitignored.

4. **File organization**: Each tool has its own directory with configuration files. Keep related configs together.

## Commit Message Convention

### Title Format

Follow this format for commit message titles:

```
[component] description
[component] subcomponent: description
[component1][component2] description
```

- **Component prefix**: Use brackets to indicate the affected tool (e.g., `[nvim]`, `[zsh]`, `[tmux]`). Multiple components can be combined: `[nvim][tmux]`.
- **Sub-component**: Optional, use colon separator (e.g., `[nvim] ai-agents: fix bug`).
- **Description**: Imperative mood, brief and descriptive.

### Commit Body

If the changes are non-trivial, also include a commit body summarizing the changes. Use bullet points to list:
- What was changed
- Why it was changed (if not obvious)
- Key implementation details

