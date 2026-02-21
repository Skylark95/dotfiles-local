# Custom Plugins for Dotbot

Dotbot can be extended with custom plugins to handle new directives.

## Creating a Plugin

A custom plugin is a Python class that inherits from `dotbot.Plugin`.

### Basic Template

```python
from dotbot.plugin import Plugin

class MyPlugin(Plugin):
    """
    Handle the 'my-directive' directive.
    """

    _directive = "my-directive"

    def can_handle(self, directive: str) -> bool:
        return directive == self._directive

    def handle(self, directive: str, data: Any) -> bool:
        if not self.can_handle(directive):
            return False
        
        # Process the directive here.
        # 'data' is the value associated with the directive in the configuration.
        self._log.info(f"Processing my-directive: {data}")
        
        return True
```

### Dry Run Support

If your plugin can safely perform a dry run (printing what it would do without actually doing it), set `supports_dry_run = True`.

```python
class MyPlugin(Plugin):
    supports_dry_run = True
    # ...
```

## Using a Custom Plugin

### Command-line Argument

You can load a custom plugin by passing its path to the `--plugin` flag:

```bash
./install --plugin path/to/my_plugin.py
```

### Configuration File

Alternatively, you can specify plugins in the configuration file using the `plugins` directive. This takes a list of paths (files or directories) containing the plugins to load. Paths are interpreted relative to the base directory.

```yaml
- plugins:
    - dotbot-plugins/dotbot-brew/
    - dotbot-plugins/custom_plugin.py
```
