# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

Machine-specific dotfiles companion to the main [dotfiles](https://github.com/Skylark95/dotfiles) repo. Manages configs that vary per-workstation or contain private data not suited for the public repo. Uses [Dotbot](https://github.com/anishathalye/dotbot) (as a git submodule) to symlink files into `~`.

## Key Commands

```bash
./install               # Symlink all files per install.conf.yaml (idempotent)
./install --dry-run     # Preview changes without applying
./install --only link   # Run only specific directives
./install --except shell  # Skip specific directives
```

After editing any config file, re-run `./install` to apply.

## Branching Strategy

- `master` — shared defaults and templates
- Machine branches (`fedora`, `popos`, `chromebook-debian`, etc.) — workstation-specific configs

To create a new machine config: branch from `master`, customize `install.conf.yaml` and local files, run `./install`. To sync improvements from `master`: `git merge master`.

## Managed Files

`install.conf.yaml` controls what gets symlinked. Current links:

| Repo file | Symlink target |
|---|---|
| `alias_local` | `~/.alias_local` |
| `env_local` | `~/.env_local` |
| `gitconfig_local` | `~/.gitconfig_local` |
| `npmrc` | `~/.npmrc` |
| `gemini/settings.json` | `~/.gemini/settings.json` |

## Adding a New Dotfile

1. Move the file into this repo directory.
2. Add an entry under `link:` in `install.conf.yaml`.
3. Run `./install`.

## Agent Skills

`.agents/skills/dotbot/` contains a reusable skill for working with Dotbot configuration. It includes reference docs (`references/`) and a template (`assets/install.conf.yaml`). The `SKILL.md` defines how agents should invoke Dotbot workflows.
