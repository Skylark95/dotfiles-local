Dotfiles (local)
================

This repository contains machine-specific configurations and local overrides to accompany my main [dotfiles](https://github.com/Skylark95/dotfiles). It is designed to handle settings that vary between workstations or contain environment-specific information that doesn't belong in the primary repository.

Branching Strategy
-----------------

This repository uses a **branch-per-machine** (or group of machines) strategy to manage diverse configurations:

- `master`: Contains common "local" defaults and templates shared across most environments.
- **Workstation branches**: Tailored configurations for specific hardware or OS distributions. Examples include:
    - `popos`: Main desktop configuration.
    - `fedora`: Fedora workstation configuration.
    - `chromebook-debian`: Linux environment on Chromebook.
    - `thinkcentre-arch` / `thinkcentre-debian`: Home server/desktop setups.
    - `linuxbrew`: Environments using Homebrew on Linux.

Key Configuration Files
----------------------

The following files are typically managed and linked by this repository (via [Dotbot](https://github.com/anishathalye/dotbot)):

- `~/.alias_local`: Custom shell aliases specific to the machine or environment.
- `~/.env_local`: Local environment variables (e.g., API keys, local paths, PATH exports).
- `~/.gitconfig_local`: Local Git user details (name, email) and machine-specific git settings.
- `~/.npmrc`: Node.js registry settings and local npm configuration.

Workflow & Installation
----------------------

### Prerequisites

Ensure the main [dotfiles](https://github.com/Skylark95/dotfiles) repository is cloned and installed first.

### Setup

1.  Clone this repository to `~/.dotfiles-local`:
    ```bash
    git clone https://github.com/Skylark95/dotfiles-local.git ~/.dotfiles-local
    ```
2.  Navigate to the directory and checkout the relevant branch for your workstation:
    ```bash
    cd ~/.dotfiles-local
    git checkout <branch-name>
    ```
3.  Run the idempotent install script:
    ```bash
    ./install
    ```
4.  (`fedora` branch only) Install the software packages these dotfiles expect via `dnf`, plus a couple of `$HOME`-local tools not packaged for Fedora:
    ```bash
    ./install-deps.sh
    ```

Adding a New Workstation
-----------------------

To set up a new environment:

1.  Create a new branch from `master`:
    ```bash
    git checkout master
    git checkout -b <new-workstation-name>
    ```
2.  Customize `install.conf.yaml` and the local files as needed.
3.  Run `./install` to link the new configurations.

Maintenance
-----------

To keep machine-specific branches up to date with common changes, periodically merge `master` into your active branch:

```bash
git merge master
```

License
-------

This software is released into the public domain. See `LICENSE.md` for details.
