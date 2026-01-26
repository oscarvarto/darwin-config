# Centralized PATH Management System

This system gives you complete control over your PATH across all shells (zsh, fish, nushell) from a single configuration file.

## 📁 Configuration Location

The PATH configuration is managed in:
```
modules/path-config.nix
```

## 🎯 Key Features

- **Single source of truth**: Modify PATH in one place, applies to all shells
- **Override mise**: Your PATH takes precedence over mise, homebrew, and other tools
- **Priority control**: Paths are listed in priority order (first = highest priority)
- **Automatic deduplication**: Removes duplicate entries automatically
- **Shell consistency**: Same PATH order and entries across zsh, fish, and nushell

## 🛠️ How to Add Custom PATH Entries

### 1. Edit the Path Configuration

Open `modules/path-config.nix` and add your custom paths at the top of the `pathEntries` list:

```nix
pathEntries = [
  # -------------------------------------------------------------------------
  # HIGH PRIORITY - YOUR CUSTOM PATHS (add your overrides here)
  # -------------------------------------------------------------------------
  "/path/to/your/priority/tools/bin"        # Highest priority
  "$HOME/my-custom-tools/bin"               # Second highest
  "/usr/local/my-app/bin"                   # Third highest
  
  # -------------------------------------------------------------------------
  # DEVELOPMENT TOOLS (existing entries continue below...)
  # -------------------------------------------------------------------------
  "$HOME/.volta/bin"
  # ... rest of the configuration
];
```

### 2. Examples of Common Custom Paths

```nix
# Custom development tools
"$HOME/go/bin"                            # Go binaries
"$HOME/.local/share/JetBrains/Toolbox/scripts"  # JetBrains tools
"/opt/local/bin"                          # MacPorts
"$HOME/.bun/bin"                          # Bun JavaScript runtime

# Language-specific tools
"$HOME/.rbenv/shims"                      # Ruby version manager
"$HOME/.pyenv/shims"                      # Python version manager
"$HOME/.flutter/bin"                      # Flutter development

# Custom project tools
"$HOME/projects/my-scripts"               # Personal scripts
"/opt/my-company/tools/bin"               # Company tools
```

### 3. Rebuild and Apply

After editing the configuration:

```bash
# Build and apply changes
ns

# Or build first, then switch
nb && ns
```

## 🔧 Advanced Usage

### Priority Control

The order in the `pathEntries` list determines priority:
- **First entry** = **Highest priority** (checked first for commands)
- **Last entry** = **Lowest priority** (checked last for commands)

### Environment Variable Expansion

You can use environment variables in paths:
- `$HOME` - User home directory
- `$DOTNET_ROOT` - .NET installation path
- `$CARGO_HOME` - Rust cargo directory

### Conditional Path Addition

Paths are only added if the directory exists, so you can safely include paths that might not be present on all systems.

## 🚫 What This Overrides

This system takes precedence over:
- ✅ **mise PATH modifications**
- ✅ **Homebrew PATH additions**
- ✅ **System PATH defaults**
- ✅ **Shell-specific PATH setup**
- ✅ **Tool-specific PATH modifications**

## 📊 Verification

After making changes, you can verify PATH consistency:

```bash
# Check PATH in all shells
echo "Zsh PATH entries: $(echo $PATH | tr ':' '\n' | wc -l)"
echo "Fish PATH entries: $(fish -c 'for p in $PATH; echo $p; end' | wc -l)"
echo "Nushell PATH entries: $(nu -c '$env.PATH | length')"

# Check for duplicates
echo $PATH | tr ':' '\n' | sort | uniq -c | sort -nr | head -5
```

## 🎯 Common Use Cases

### Adding a New Development Tool

1. Install the tool (e.g., with homebrew, cargo, npm, etc.)
2. Add its bin directory to the top of `pathEntries` in `path-config.nix`
3. Rebuild with `ns`
4. The tool will be available with highest priority in all shells

### Overriding System Tools

```nix
pathEntries = [
  "/opt/homebrew/bin"                     # Homebrew version takes priority
  "/usr/local/bin"                        # User-installed version
  "/usr/bin"                              # System version (lowest priority)
  # ...
];
```

### Project-Specific Tools

```nix
pathEntries = [
  "$HOME/current-project/scripts"         # Current project tools
  "$HOME/.local/bin"                      # General user tools
  # ...
];
```

Remember: Changes take effect after rebuilding your darwin-config with `ns`!
