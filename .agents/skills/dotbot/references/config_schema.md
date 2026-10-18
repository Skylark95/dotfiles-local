# Dotbot Configuration Schema

Dotbot configuration is typically a YAML file (e.g., `install.conf.yaml`) containing a list of directives.

## Top-level Structure

The configuration is a list of objects, where each object's key is a directive name.

```yaml
- defaults:
    link:
      relink: true

- clean: ['~']

- create:
    - ~/downloads

- plugins:
    - dotbot-plugins/dotbot-brew/
    - dotbot-plugins/custom_plugin.py

- link:
    ~/.tmux.conf: tmux.conf
    ~/.vim: vim
    ~/.vimrc: vimrc

- shell:
    - [git submodule update --init --recursive, Installing submodules]
```

## Global Options

### Defaults

The `defaults` directive sets default values for other directives.

```yaml
- defaults:
    link:
      relink: true
      create: true
```

## Directives

Common directives include `link`, `create`, `shell`, and `clean`. See [builtin_plugins.md](builtin_plugins.md) for details on each.
