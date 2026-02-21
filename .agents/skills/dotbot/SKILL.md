---
name: dotbot
description: Manage dotfiles using Dotbot. Use when you need to install dotfiles, update configuration, or manage plugins.
---

# Dotbot Skill

Dotbot is a tool for managing dotfiles through a simple configuration file.

## Common Workflows

### Install Dotfiles

To install dotfiles managed by Dotbot, use the `install` shim provided in your dotfiles repository:

```bash
./install
```

By default, the script assumes the configuration is in `install.conf.yaml`.

### Dry Run

Before applying changes, it's recommended to perform a dry run to see what would happen:

```bash
./install --dry-run
```

### Add a New Dotfile

To add a new dotfile to be managed by Dotbot:

1. Move the original file into your dotfiles repository.
2. Edit `install.conf.yaml` and add a new entry under the `link` directive.
3. Run Dotbot to create the symlink.

Example:
```yaml
- link:
    ~/.gitconfig: gitconfig
```

### Advanced Command-line Arguments

For more granular control over which directives are executed, use the `--only` or `--except` flags:

- **Run only specific directives:**
  ```bash
  ./install --only link shell
  ```
- **Skip specific directives:**
  ```bash
  ./install --except shell
  ```

## References

- [config_schema.md](references/config_schema.md): Detailed documentation on the configuration file structure.
- [builtin_plugins.md](references/builtin_plugins.md): Documentation on built-in directives like `link`, `create`, `shell`, and `clean`.
- [custom_plugins.md](references/custom_plugins.md): Guide for creating and using custom plugins.

## Assets

- [install.conf.yaml](assets/install.conf.yaml): A basic template for a new Dotbot configuration.
