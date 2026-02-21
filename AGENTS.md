# Dotfiles (Local) Project Overview

This project serves as a machine-specific companion to a primary dotfiles repository. It manages environment variables, aliases, and configurations that are either sensitive (like private email addresses) or specific to the local workstation's hardware and operating system.

## Project Structure and Purpose

- **Type**: Dotfiles Management (using [Dotbot](https://github.com/anishathalye/dotbot))
- **Primary Goal**: To provide a clean way to override or extend global dotfile settings for a specific machine without polluting the main dotfiles repository.
- **Companion Relationship**: This repository is designed to be cloned into `~/.dotfiles-local` and is referenced by the main `~/.dotfiles` project.

## Key Files and Configurations

### Installation and Management
- `install`: A bash script that initializes the Dotbot submodule and runs the installation based on `install.conf.yaml`.
- `install.conf.yaml`: The Dotbot configuration file that defines which files should be symlinked to the user's home directory.
- `install.ps1`: A PowerShell alternative for Windows environments.

### Local Overrides
- `env_local`: Manages local environment variables, including `PATH` extensions (e.g., Homebrew, local bin directories, Bun, npm-global).
- `alias_local`: Defines machine-specific shell aliases.
- `gitconfig_local`: Contains local Git user identity (name/email).
- `npmrc`: Sets local npm configurations, such as the global prefix (`~/.npm-global`).

## Branching Strategy

The project employs a **branch-per-machine** strategy:
- `master`: Holds common defaults and templates.
- **Machine branches** (e.g., `popos`, `chromebook-debian`): Contain the actual configurations used on specific workstations. 

To update a specific machine's config, checkout its branch and merge from `master` if needed.

## Usage and Development

### Setting Up a New Machine
1. Clone the repository to `~/.dotfiles-local`.
2. Checkout the appropriate branch (or create a new one from `master`).
3. Run `./install`.

### Modifying Configuration
- Edit the relevant `*_local` file or `install.conf.yaml`.
- Run `./install` again (it is idempotent) to apply changes.
- Commit and push the changes to the machine-specific branch.

## Building and Testing
As this is a dotfiles project, there is no traditional build step.
- **Test**: Run `./install` and verify symlinks are correctly created in `~`.
- **Validation**: Source the local environment files (e.g., `source ~/.env_local`) to ensure they load without errors.
