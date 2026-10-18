# Built-in Plugins for Dotbot

Dotbot includes several built-in plugins (directives) to manage dotfiles.

## `link`

Symbolically links dotfiles.

### Syntax

```yaml
- link:
    ~/.bashrc: bashrc
    ~/.vimrc:
      path: vimrc
      force: true
      relink: true
```

### Options

| Option | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `path` | string | | Target file (the source file in your dotfiles repo). |
| `if` | string | | Shell command to test. Only links if the command returns success (exit code 0). |
| `relative` | bool | `false` | Use relative paths for symlinks. |
| `canonicalize` | bool | `true` | Canonicalize paths. |
| `type` | string | `symlink` | `symlink` or `hardlink`. |
| `force` | bool | `false` | Overwrite existing files. |
| `relink` | bool | `false` | Relink if the target is different. |
| `create` | bool | `false` | Create parent directories if they don't exist. |
| `glob` | bool | `false` | Treat path as a glob. |
| `backup` | bool | `false` | Backup existing files before overwriting. |
| `prefix` | string | | Prefix for globbed files. |
| `ignore-missing` | bool | `false` | Ignore missing source files. |
| `exclude` | list | `[]` | Paths to exclude when globbing. |

### Implicit Targets

If the target `path` is omitted or set to `null`, Dotbot uses the basename of the link name, with any leading `.` stripped. For example, `~/.vimrc: null` will link to `vimrc` in the base directory.

### Globbing Nuances

When `glob: true`, Dotbot uses standard shell-style wildcards.
- **Hidden Files:** Patterns like `config/*` will **not** match hidden files (starting with `.`). To match hidden files, use a pattern like `config/.*`.
- **Exclusions:** Paths in the `exclude` list must be relative to the base directory, matching the style of the `path` pattern.

## `create`

Creates directories.

### Syntax

```yaml
- create:
    - ~/Downloads
    - path: ~/Projects
      mode: 0o755
```

### Options

| Option | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `path` | string | | Path to the directory to create. |
| `mode` | octal | `0o777` | Directory permissions (filtered by system `umask`). |

## `shell`

Runs shell commands.

### Syntax

```yaml
- shell:
    - [git submodule update --init --recursive, Installing submodules]
    - command: ls -la
      description: Listing files
      stdout: true
```

### Options

| Option | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `command` | string | | Command to execute. |
| `description` | string | | Description shown while running. |
| `stdin` | bool | `false` | Enable stdin for the command. |
| `stdout` | bool | `false` | Show command output. |
| `stderr` | bool | `false` | Show command error output. |
| `quiet` | bool | `false` | Suppress printing the command string in the log output (does not affect `stdout`/`stderr`). |
| `if` | string | | Shell command to test. Only runs if the command returns success. |

## `clean`

Removes broken symlinks in specified directories.

### Syntax

```yaml
- clean:
    - '~'
    - path: ~/.config
      recursive: true
```

### Options

| Option | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `path` | string | | Directory to clean. |
| `force` | bool | `false` | Force removal even if not a symlink (be careful!). |
| `recursive` | bool | `false` | Clean directories recursively. |
