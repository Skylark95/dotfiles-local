# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

Machine-specific dotfiles companion to the main [dotfiles](https://github.com/Skylark95/dotfiles) repo. Manages configs that vary per-workstation or contain private data not suited for the public repo. Uses [Dotbot](https://github.com/anishathalye/dotbot) (as a git submodule) to symlink files into `~`.

## Key Commands

```bash
./install               # Symlink all files per install.conf.yaml (idempotent)
./install --only link   # Run only specific directives
./install --except shell  # Skip specific directives
```

`./install` also runs `git submodule sync` and `git submodule update --init --recursive` (the `shell` directive). After editing any config file, re-run `./install` to apply.

## Claude Code Status Line

`claude/statusline-command.sh` is pure `sh` + `jq` + `git`, run as `sh ~/.claude/statusline-command.sh`. Keep it executable.

- Colors are terminal palette indices (e.g. `44`, `48;5;169`), not truecolor. Claude Code downsamples RGB to the 256-color cube, so the Ghostty Dracula theme supplies the exact colors.
- Width comes from `$COLUMNS` (set by Claude Code) minus 4 for its built-in margin. The right group wraps to a second line if there is no room.
- The line renders above Claude's built-in footer. It cannot be reordered and the footer's mode badge cannot be hidden.

## Branching Strategy

Each branch targets a specific machine or group of machines. `master` holds shared defaults; every other branch is workstation-specific. Run `git branch -r` for the current list (at the time of writing: `android`, `chromebook`, `chromebook-debian`, `debian`, `fedora`, `linuxbrew`, `linuxbrew-debian`, `popos`, `thinkcentre`, `thinkcentre-arch`, `thinkcentre-debian`).

- **New machine:** branch from `master`, customize `install.conf.yaml` and local files, run `./install`.
- **Shared changes:** make them on `master`, then run `git merge master` on each machine branch that needs them.
- **Machine-specific changes:** work on the matching branch and consider whether related branches (e.g. `chromebook` / `chromebook-debian`) need the same change.

Before pushing a machine branch, `git fetch` first. `fedora` has diverged from `origin/fedora` before. Rebase onto the remote rather than force-pushing, and merge `claude/settings.json` by hand, since other machines share it.

## Managed Files

`install.conf.yaml` controls what gets symlinked. On `master` the links are:

| Repo file | Symlink target |
|---|---|
| `alias_local` | `~/.alias_local` |
| `env_local` | `~/.env_local` |
| `gitconfig_local` | `~/.gitconfig_local` |
| `claude/settings.json` | `~/.claude/settings.json` |
| `claude/statusline-command.sh` | `~/.claude/statusline-command.sh` |
| `gemini/settings.json` | `~/.gemini/settings.json` |

Machine branches add their own entries, for example `npmrc` → `~/.npmrc`, `ghostty/*`, `bin/pt`, or `systemd/rclone@.service`. Check the branch's `install.conf.yaml` for the real list.

These are machine-local overrides that the main dotfiles repo includes (e.g. `.gitconfig_local` via the main `.gitconfig`'s `[include]`, and `.env_local` / `.alias_local` sourced by the main `zshrc`).

## Conventions for `env_local`

`env_local` is shared across machines, so per-tool PATH entries must be safe where the tool is absent. Guard each one with `[ -d ... ]` or `[ -f ... ]` and use `$HOME` rather than a hardcoded home directory.

## Adding a New Dotfile

1. Move the file into this repo directory.
2. Add an entry under `link:` in `install.conf.yaml`.
3. Run `./install`.

## Agent Skills

`.agents/skills/dotbot/` contains a reusable skill for working with Dotbot configuration (reference docs in `references/`, a template in `assets/install.conf.yaml`, and a `SKILL.md` defining how agents invoke Dotbot workflows).
