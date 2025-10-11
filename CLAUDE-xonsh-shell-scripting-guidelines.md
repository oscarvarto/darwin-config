# Xonsh Shell Scripting Guidelines

## Overview

Xonsh is a Python-powered shell that combines Python's expressiveness with subprocess capabilities. When writing xonsh scripts (`.xsh` files), follow these guidelines to avoid common pitfalls.

## Core Principle: Python Mode vs Subprocess Mode

**Xonsh has two distinct modes that should NEVER be mixed in the same expression:**

1. **Python Mode** - Standard Python code (variables, functions, imports, control flow)
2. **Subprocess Mode** - Shell commands with `!()` syntax or bare commands

## Environment Variable Access

### ❌ WRONG - Don't use `${...}` in Python expressions

```python
# WRONG - ${...} is subprocess syntax, cannot be used in Python code
path_str = ${...}.get('DARWIN_CONFIG_PATH', '')
if 'HOSTNAME' in ${...}:
    return ${...}['HOSTNAME']
```

### ✅ CORRECT - Use `os.environ` for Python mode

```python
# CORRECT - Use standard Python os.environ
import os
path_str = os.environ.get('DARWIN_CONFIG_PATH', '')
if 'HOSTNAME' in os.environ:
    return os.environ['HOSTNAME']
```

**Why:** `${...}` is subprocess mode syntax for environment variables and can return lists or special `EnvPath` objects. In Python code, always use `os.environ` which returns plain strings.

## Subprocess Calls

### ❌ WRONG - Don't use `!()` with variable interpolation in Python expressions

```python
# WRONG - Mixing subprocess syntax with Python expressions
result = !(nix eval --expr @(nix_expr))
result = !(command --flag @(variable))
with ${...}.swap(PWD=path):  # Wrong environment access
    result = !(command)
```

### ✅ CORRECT - Use `subprocess.run()` for reliable execution

```python
# CORRECT - Use standard Python subprocess module
import subprocess

result = subprocess.run(
    ['nix', 'eval', '--expr', nix_expr],
    capture_output=True,
    text=True,
    cwd=str(config_path)  # Optional: set working directory
)

if result.returncode != 0:
    raise RuntimeError(f"Command failed: {result.stderr}")
return result.stdout.strip()
```

**Why:** The `!()` subprocess syntax with `@()` interpolation can cause parsing errors. Standard Python `subprocess` module is more reliable and explicit.

## Directory Changes in Subprocess Context

### ❌ WRONG - Don't use chained commands with `&&`

```python
# WRONG - && is not supported in xonsh subprocess mode
result = !(cd @(path) && command)
```

### ✅ CORRECT - Use `cwd` parameter in subprocess.run()

```python
# CORRECT - Use cwd parameter
result = subprocess.run(
    ['command', 'arg'],
    cwd=str(path),
    capture_output=True,
    text=True
)
```

## Module Imports and Shared Code

### ❌ WRONG - Don't use `importlib` or `source` for xonsh files

```python
# WRONG - importlib doesn't work with xonsh files
import importlib.util
spec = importlib.util.spec_from_file_location("lib", lib_path)
lib = importlib.util.module_from_spec(spec)

# WRONG - source doesn't import variables into namespace
source @(lib_path)
```

### ✅ CORRECT - Use `exec(compile())` pattern

```python
# CORRECT - Execute xonsh file in current namespace
from pathlib import Path

lib_path = Path(__file__).parent / "shared-lib.xsh"
with open(lib_path) as f:
    exec(compile(f.read(), str(lib_path), 'exec'))

# Now all variables/functions from shared-lib.xsh are available
```

**Why:** Xonsh files need special handling. The `exec(compile())` pattern properly imports all variables and functions into the current namespace.

## Required Imports

Always include these imports at the top of xonsh scripts:

```python
#!/usr/bin/env xonsh
import sys
import os
import subprocess
from pathlib import Path
```

## Running Xonsh Scripts from Nix

When creating Nix wrappers for xonsh scripts, use `--no-rc` flag:

```nix
pkgs.writeScriptBin "my-tool" ''
  #!/usr/bin/env bash
  # --no-rc: Skip loading ~/.xonshrc to avoid xontrib warnings in non-interactive mode
  exec ${pkgs.xonsh}/bin/xonsh --no-rc "${scriptPath}/my-tool.xsh" "$@"
''
```

## Common Patterns

### Reading Environment Variables

```python
# Get with default
config_path = os.environ.get('DARWIN_CONFIG_PATH', '')

# Check existence
if 'HOSTNAME' in os.environ:
    hostname = os.environ['HOSTNAME']

# Always convert to string if needed
path_str = str(os.environ.get('VAR', ''))
```

### Running External Commands

```python
# Simple command
result = subprocess.run(
    ['git', 'status'],
    capture_output=True,
    text=True
)

# Command with working directory
result = subprocess.run(
    ['nix', 'eval', '--raw', '--impure', '--expr', expression],
    cwd=str(config_path),
    capture_output=True,
    text=True
)

# Check result
if result.returncode != 0:
    print(f"Error: {result.stderr}", file=sys.stderr)
    sys.exit(1)

output = result.stdout.strip()
```

### Error Handling

```python
try:
    result = subprocess.run(
        ['command', 'arg'],
        capture_output=True,
        text=True,
        check=False  # Don't raise on non-zero exit
    )
    if result.returncode != 0:
        raise RuntimeError(f"Command failed: {result.stderr}")
except Exception as e:
    print(f"❌ Error: {e}", file=sys.stderr)
    sys.exit(1)
```

## Troubleshooting Common Errors

### Error: "invalid syntax" with `${...}`

**Cause:** Trying to use subprocess syntax in Python expression
**Fix:** Replace `${...}` with `os.environ`

### Error: "argument should be a str... not 'EnvPath'"

**Cause:** `__xonsh__.env` returns special objects
**Fix:** Use `os.environ` which always returns strings

### Error: "invalid syntax" with `!(command @(var))`

**Cause:** Mixing subprocess syntax with Python
**Fix:** Use `subprocess.run(['command', var])` instead

### Error: "'NoneType' object has no attribute 'loader'"

**Cause:** Using `importlib` with xonsh files
**Fix:** Use `exec(compile())` pattern for imports

### Error: "name 'VARIABLE' is not defined" after source

**Cause:** `source` doesn't import variables
**Fix:** Use `exec(compile())` pattern

## Best Practices

1. **Prefer `os.environ` over any xonsh-specific environment access** in Python code
2. **Use `subprocess.run()` for all external commands** - it's explicit and portable
3. **Import shared xonsh code with `exec(compile())`** - only reliable pattern
4. **Always include proper imports** (`sys`, `os`, `subprocess`, `pathlib`)
5. **Use `--no-rc` flag** when running xonsh scripts non-interactively
6. **Test scripts independently** before integrating into Nix configuration
7. **Keep Python mode and subprocess mode strictly separated**

## Example: Well-Structured Xonsh Script

```python
#!/usr/bin/env xonsh
"""
My Xonsh Tool - Description

This script demonstrates proper xonsh patterns.
"""

import sys
import os
import subprocess
from pathlib import Path

# Constants
CACHE_DIR = Path.home() / ".cache"
CONFIG_FILE = CACHE_DIR / "config"

# Import shared library
lib_path = Path(__file__).parent / "lib.xsh"
with open(lib_path) as f:
    exec(compile(f.read(), str(lib_path), 'exec'))

def main():
    # Get environment variable
    config_path = os.environ.get('MY_CONFIG_PATH', '')
    if not config_path:
        print("❌ MY_CONFIG_PATH not set", file=sys.stderr)
        sys.exit(1)

    # Run external command
    try:
        result = subprocess.run(
            ['git', 'status'],
            cwd=config_path,
            capture_output=True,
            text=True
        )
        if result.returncode != 0:
            raise RuntimeError(f"Git failed: {result.stderr}")

        print(f"✅ Success: {result.stdout.strip()}")
        return 0

    except Exception as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        return 1

if __name__ == "__main__":
    sys.exit(main())
```

## References

- [Xonsh Documentation](https://xon.sh/)
- [Bash to Xonsh Translation Guide](https://xon.sh/bash_to_xsh.html)
- [Xonsh Tutorial](https://xon.sh/tutorial.html)

---

**Created:** 2025-10-09
**Context:** Lessons learned from migrating Emacs pinning scripts from bash to xonsh
**Last Updated:** Based on troubleshooting session with environment variables, subprocess calls, and module imports
