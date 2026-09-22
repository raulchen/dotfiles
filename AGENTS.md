# AGENTS.md

This dotfiles repository contains configuration files for various development tools. This guide helps AI agents understand the project structure and conventions.

## Project Structure

- **`nvim/`** - Neovim configuration (Lua-based)
  - `init.lua` - Entry point, sets up lazy.nvim
  - `lua/core/` - Core settings (options, keymaps, autocmds)
  - `lua/plugins/` - Plugin configurations
  - `lua/util/` - Shared Lua utilities
- **`vim/`** - Vim configuration (vim-plug based)
- **`zsh/`** - Zsh configuration (zshrc, aliases, functions, theme)
- **`tmux/`** - Tmux configuration
- **`hammerspoon/`** - macOS automation scripts (macOS only)
- **`macos/`** - macOS-specific system configuration and setup scripts
- **`git/`** - Git configuration
- **`wezterm/`** - WezTerm terminal configuration
- **`ghostty/`** - Ghostty terminal configuration
- **`lsd/`** - lsd (ls alternative) configuration
- **`yazi/`** - Yazi terminal file manager configuration
- **`claude/`** - Claude Code settings and keybindings
- **`codex/`** - Codex configuration and hooks
- **`bin/`** - Human-facing commands and utility scripts; added to `PATH`
- **`libexec/`** - Internal executables invoked by configurations and other scripts; not intended for direct use
- **`installers/`** - Per-tool installation scripts
- **`setup.sh`** - Main setup script that creates configuration symlinks

## Key Conventions

- **Neovim plugins**: Managed by lazy.nvim and stored in `~/.local/share/nvim/lazy/`. Always check plugin code when configuring or using plugin APIs.

- **Symlink setup**: The `setup.sh` script creates symlinks from this repository to standard config locations (e.g., `nvim/` → `~/.config/nvim`).

- **Codex configuration**: Put portable, globally applicable Codex settings in this repository under `codex/`. Keep machine-local Codex settings in `~/.codex/config.toml`.

- **Local overrides**: Some tools support local config files (e.g., `hammerspoon/local.lua`, `*.local` files) which are gitignored.

- **File organization**: Each tool has its own directory with configuration files. Keep related configs together.

- **Temporary files**: Never create `nvim.log` or any other logs, test artifacts, caches, or temporary files anywhere in this repository. Direct all temporary output to `/tmp` instead.

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
