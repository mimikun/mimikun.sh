# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a collection of personal shell scripts (mimikun.sh) with dual implementations in Bash and PowerShell. The project is planned to be rewritten in deno-dax. Scripts are organized by function (chezmoi hooks, package management, system utilities).

## LLM Context Documents

Extended context and documentation for LLMs (AI assistants) are stored in `docs/llms/`:
- `docs/llms/rewrite-context.md` - Context and requirements for code rewrites
- `docs/llms/rewrite-progress.md` - Progress tracking for ongoing rewrites

## Common Commands

### Linting and Testing

```bash
# Run all lints (textlint, typos, shellcheck, shfmt, PSScriptAnalyzer)
mise tasks run lint
# or
make lint

# Run PowerShell Script Analyzer only
mask pwsh-test

# Run shell lints only (Linux)
mask shell-lint
```

### Formatting

```bash
# Format shell scripts with shfmt
mise tasks run format
# or
make fmt
```

### Git Workflow

```bash
# Create patch branch for daily work
mise tasks run patch:branch

# Create and copy patch to Windows
make patch

# Morning routine (fetch, cleanup branches, pull, create patch branch)
mise tasks run git:morning-routine

# Push to remotes (checks for work PC to prevent accidental pushes)
mise tasks run git:push
```

### Installation

```bash
# Install all scripts to ~/.local/bin/
make install
```

## Architecture

### Dual Implementation Pattern

Most functionality has parallel implementations:
- `src/*.sh` - Bash scripts for Linux/macOS
- `powershell/*.ps1` - PowerShell scripts for Windows

### Script Organization

- `src/chezmoi/` - Pre/post hooks for chezmoi dotfile management
- `src/generate/` - Scripts to generate package lists (cargo, pip, pipx, uv)
- `src/install/` - Package installation scripts
- `src/update/` - Update scripts for various tools
- `src/misc/` - Utility scripts (editorconfig generation, system reboot/shutdown)

### Task Automation

The project uses multiple task runners in parallel:
- **mise** - Primary task runner (`.mise.toml` and mise tasks in dirs)
- **mask** - Cross-platform task runner (`maskfile.md`)
- **make** - Traditional makefile, mostly delegates to mise

### Key Patterns

1. **Patch-based development**: Daily work done in `patch-YYYYMMDD` branches
2. **Work PC detection**: Scripts check hostname to prevent accidental pushes from work machines
3. **Cross-platform support**: Dual Bash/PowerShell implementations with platform detection
4. **Package management abstraction**: Unified scripts for managing cargo, pip, pipx, uv packages
