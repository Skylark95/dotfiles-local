# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a machine-specific dotfiles repo that works alongside the main [dotfiles](https://github.com/Skylark95/dotfiles) repository. Configuration for specific machines (or groups of machines) is maintained in **separate git branches** — each branch represents a different machine or OS configuration.

## Installation

```bash
./install
```

The install script is idempotent and uses [Dotbot](https://github.com/anishathalye/dotbot) (included as a git submodule) to symlink config files and run shell setup steps.

## Branch Structure

Each branch targets a specific machine/environment. Current branches include:
- `master` — base/shared config
- `chromebook`, `chromebook-debian` — Chromebook variants
- `debian`, `linuxbrew-debian` — Debian variants
- `linuxbrew` — Linuxbrew-based setup
- `thinkcentre`, `thinkcentre-arch`, `thinkcentre-debian` — ThinkCentre variants

When making changes for a specific machine, work on the appropriate branch and consider whether changes should be merged/rebased into related branches.

## What Gets Linked (`install.conf.yaml`)

| Symlink target | Source |
|---|---|
| `~/.alias_local` | `alias_local` |
| `~/.env_local` | `env_local` |
| `~/.gitconfig_local` | `gitconfig_local` |
| `~/.npmrc` | `npmrc` |
| `~/.config/kitty/local.conf` | `kitty/local.conf` |

These files are machine-local overrides that the main dotfiles repo includes (e.g., `.gitconfig_local` is included by the main `.gitconfig` via `[include]`).
