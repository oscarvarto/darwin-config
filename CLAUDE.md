# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a comprehensive macOS system configuration using Nix-Darwin and Home Manager with flakes. The repository configures an entire macOS development environment including packages, applications, shell configurations, editors, and secrets management.

**Current Branch**: feature/emacs - Enhanced Emacs integration with home-manager service, version pinning, and improved macOS support.

## Essential Build Commands

### Core Development Workflow
- `nb` - Build darwin configuration (preferred alias for `nix run .#build`)
- `ns` - Build and switch to new configuration (preferred alias for `nix run .#build-switch`)
- `./apps/aarch64-darwin/build` - Direct build script (Apple Silicon)
- `./apps/aarch64-darwin/build-switch` - Direct build and switch script
- `./apps/aarch64-darwin/rollback` - Rollback to previous generation
- `nix run .#apply` - Apply user/secrets repo placeholders into files

### Emacs Management (NEW in feature/emacs)
- `emacs-pin [commit]` - Pin Emacs to specific commit or current version (automatically called after `ns`)
- `emacs-unpin` - Unpin Emacs to use latest from overlay
- `emacs-pin-diff` - Show differences between pinned and latest Emacs
- `emacs-pin-status` - Show current Emacs pinning status
- `emacs-service-toggle` - Toggle Emacs home-manager service on/off
- `emacsclient-gui` - Launch Emacs GUI with proper macOS integration

### Validation & Development
- `nix flake check` - Validate flake configuration and evaluate checks
- `nix fmt .` - Format Nix files
- `nix develop` - Enter development shell (sets EDITOR=nvim, provides git, bash)
- `smart-gc clean` - Cleanup old generations (keeps last 3)
- `smart-gc status` - Check system status and disk usage

### Configuration Management
- `nix run .#add-host -- --hostname HOST --user USER` - Add new host to flake
- `nix run .#configure-user -- --user USER --hostname HOST` - Configure for specific user/hostname
- `nix run .#update-doom-config` - Update Doom Emacs configuration

### SSH Keys and Basic Secrets
- `./apps/aarch64-darwin/check-keys` - Check if required SSH keys exist
- `./apps/aarch64-darwin/create-keys` - Create SSH keys (id_ed25519, id_ed25519_agenix)
- `./apps/aarch64-darwin/copy-keys` - Copy SSH keys from mounted USB to ~/.ssh

### Enhanced Secret Management (Unified CLI)
- `secret status` - Show status of all credential systems
- `secret list` - List available agenix secrets
- `secret create <name>` - Create new agenix secret
- `secret edit <name>` - Edit existing agenix secret
- `secret show <name>` - Display decrypted secret content
- `secret rekey` - Re-encrypt all agenix secrets with current keys
- `secret sync-git` - Update git configs from 1Password/pass credentials
- `secret op-get <item>` - Get 1Password item
- `secret pass-get <path>` - Get pass entry
- `backup-secrets` - Backup all secrets, keys, and configurations
- `setup-secrets-repo` - Clone and setup secrets repository

### Font Management
- `detect-fonts status` - Show availability of programming fonts
- `detect-fonts emacs-font` - Get recommended font key for Emacs
- `detect-fonts ghostty-font` - Get recommended font name for terminals
- `ghostty-config font "Font Name"` - Switch terminal font

### GNU Stow Package Management
- `manage-stow-packages deploy` - Deploy all stow packages
- `manage-stow-packages remove` - Remove all stow packages
- `stow -t ~ PACKAGE` - Deploy specific package (**CRITICAL**: -t ~ target flag is REQUIRED)
- `stow -D -t ~ PACKAGE` - Remove specific package (**CRITICAL**: always include -t ~ flag)
- `manage-cargo-tools install` - Install Rust/Cargo tools from cargo-tools.toml
- `manage-nodejs-tools install` - Install Node.js toolchain from nodejs-tools.toml
- `manage-dotnet-tools install` - Install .NET SDK and tools from dotnet-tools.toml

## Code Architecture

### Primary Structure
```
flake.nix                     # Main flake with host configurations
system.nix                    # System-level macOS configuration  
modules/                      # Modular configuration components
├── home-manager.nix          # User environment & Home Manager config
├── packages.nix              # Nix packages (CLI tools, dev tools)
├── casks.nix                 # Homebrew casks (GUI applications)
├── brews.nix                 # Homebrew formulas (additional CLI)
├── path-config.nix           # Centralized PATH management
├── secrets.nix               # Age-encrypted secrets with agenix
├── enhanced-secrets.nix      # Unified secret management CLI
├── secure-credentials.nix    # 1Password/pass integration
├── emacs-pinning.nix         # Emacs version pinning system (NEW)
├── terminal-support.nix      # Ghostty terminfo support (NEW)
├── biometric-auth.nix        # macOS biometric authentication (NEW)
├── starship.toml             # Starship prompt with Catppuccin theme
└── [various other modules]
```

### Multi-User/Multi-Host Design
- Host configurations defined in `flake.nix` `hostConfigs` section
- Each host specifies: user, system architecture, defaultShell, hostSettings
- Supports personal/work profiles with conditional configuration
- Shell choice per host: "nushell" or "zsh"

### Configuration Layer Structure
1. **System Layer** (`system.nix`) - macOS system settings, services
2. **Package Layer** (`modules/packages.nix`) - Nix packages
3. **Application Layer** (`modules/casks.nix`, `brews.nix`) - GUI apps via Homebrew  
4. **User Layer** (`modules/home-manager.nix`) - User environment, dotfiles
5. **Stow Layer** (`stow/`) - Complex configurations (editors, scripts)

## Key Architectural Patterns

### Secrets Management (Multi-Layer)
- **agenix**: SSH keys, certificates, system secrets (encrypted with age)
- **1Password**: User credentials, API tokens (enterprise-grade auth)
- **pass**: Backup credential store (offline, GPG-encrypted)
- **Unified CLI**: Single `secret` command for all credential systems

### PATH Management (Centralized)
- All PATH configuration in `modules/path-config.nix`
- Overrides mise, homebrew, and other tools
- Consistent across both shells (zsh, nushell)
- Priority-ordered entries with automatic deduplication

### Font System (Intelligent Fallback)
- **Font detection**: Uses `fc-list` for accurate family name matching
- **Preference hierarchy**: MonoLisa Variable → PragmataPro Liga → JetBrains Mono → system fonts
- **Emacs integration**: F8 key cycles through fonts (preserving existing functionality)
- **Terminal integration**: Ghostty includes font fallback chain in base configuration
- **Open-source fallback**: JetBrains Mono provided via Nix packages (jetbrains-mono)
- **Optimized settings**: Each font includes ligature configuration and optimal sizes
- **Graceful degradation**: Missing commercial fonts don't break applications

### Shell Configuration (Multi-Shell Support)
- Supports nushell and zsh with feature parity
- Shared aliases, PATH, development tools across both shells
- Shell-specific strengths preserved (nushell data processing, zsh compatibility)
- Consistent Starship prompts, Zoxide navigation, Atuin history
- Note: Fish shell binary is installed only as a completion engine for Nushell

## Development Tools Integration

### Editor Configurations (via Stow)
- **Doom Emacs**: `stow/doom-emacs/` - Complete modular configuration
  - Now uses Emacs from Nix packages with home-manager service
  - Removed Scala support, focused on core languages
  - Enhanced terminal compatibility (Ghostty support)
- **LazyVim**: `stow/lazyvim/` - Modern Neovim setup with Lisp/Elisp support
  - Added `lisp.lua` and `elisp.lua` plugins for Lisp editing
  - Parinfer support for structural editing
- Font cycling with F8, LSP support, AI integration
- Emacs service managed by home-manager with proper daemon support

### Tool Management Scripts (via Stow)
- `manage-cargo-tools install` - Rust tools from cargo-tools.toml
- `manage-nodejs-tools install` - Node.js toolchain from nodejs-tools.toml  
- `manage-dotnet-tools install` - .NET SDK from dotnet-tools.toml
- `manage-stow-packages deploy` - Deploy all stow configurations

### Development Utilities
- `cleanup-intellij [project]` - Clean IntelliJ IDEA caches and state
- Git configurations with conditional work/personal configs
- Enhanced shell functions and aliases

## Testing & Validation

**There is no traditional test suite in this repository.** Instead, validation occurs through:

### Build Testing
- `nix flake check` - Validates all flake outputs and configurations
- `nix run .#build` - Tests that configuration builds successfully
- Configuration scripts include `--dry-run` modes for safe testing

### Configuration Validation
- Scripts validate host configs exist before applying
- Automatic rollback on build failures
- Syntax validation for complex configurations (Doom Emacs elisp)

## Important Implementation Notes

### Multi-User Adaptation
- Add new hosts via `nix run .#add-host`
- Host-specific settings in `flake.nix` `hostConfigs`
- Work/personal profiles affect git configs, directory structures

### Secrets Workflow
- System secrets managed via agenix (encrypted in git)
- User credentials via 1Password/pass (not stored in git)
- `secret` command provides unified interface
- Automatic git credential synchronization

### Stow Package Management (**CRITICAL USAGE PATTERNS**)
- Complex configurations managed via GNU Stow
- Symlinks from `stow/package-name/` to home directory
- **CRITICAL**: Always use `stow -t ~` syntax - the target directory flag is REQUIRED
- **CRITICAL**: Use `manage-stow-packages` command (not manage-aux-scripts)
- Use for editors, scripts, tool configurations that are difficult to embed in Nix
- Package structure mirrors home directory layout for automatic placement
- Most scripts symlinked to `~/.local/share/bin`
- **NEW**: Enhanced Emacs service scripts in `stow/nix-scripts/`

### PATH Override Strategy
- `modules/path-config.nix` takes absolute precedence
- Add custom paths at top of `pathEntries` list
- Rebuild with `ns` to apply changes
- Overrides mise, homebrew, system defaults

## Common Patterns

### Adding New Software
1. Check if available as Nix package (`modules/packages.nix`)
2. If GUI app, add to Homebrew casks (`modules/casks.nix`)
3. If CLI tool, add to Homebrew brews (`modules/brews.nix`)
4. Rebuild with `nb && ns`

### Managing Emacs Versions
1. Pin to current: `emacs-pin` (no args) - **automatically called after every `ns`**
2. Pin to specific: `emacs-pin abc123def`
3. Check status: `emacs-pin-status`
4. Unpin for latest: `emacs-unpin`
5. Rebuild: `nb && ns` (automatically pins Emacs after switch)

#### Emacs Pinning Behavior (Contributor Notes)
- Pin state files (in `~/.cache`):
  - `emacs-git-pin` (commit), `emacs-git-pin-hash` (SRI), `emacs-git-store-path` (built outPath)
- Behavior matrix:
  - Pinned + stored path exists → `configuredEmacs` re-exports that exact path; overlay updates do not rebuild.
  - Pinned + stored path missing (GC’d) → build latest overlay commit; after switch, `ns` auto-runs `emacs-pin` to lock to that new build.
  - Unpinned → always use latest overlay commit; `ns` auto-pins after successful switch.
- Scripts:
  - `emacs-pin` captures the already-built `configuredEmacs` outPath before changing pin state to avoid rebuild.
  - `emacs-pin-status` prints overlay commit, pinned commit, stored hash, and stored path if present.
- Caveat: Pinning to an older commit only avoids rebuild if that exact build already exists locally. Otherwise, next `ns` will build latest and auto-pin to it by design.

##### Impure vs. Pure Evaluation
- Why: Reusing a previously built Emacs relies on reading `~/.cache/emacs-git-store-path` during evaluation, which is an impure input.
- Default: `nb`/`ns` now default to impure evaluation so `configuredEmacs` can re-export the stored path when pinned and present (no rebuild on overlay updates).
- Force pure (reproducible eval, no reuse): add `--pure` or set `NS_IMPURE=0` when running `nb`/`ns`.
- Explicit impure: add `--impure` or set `NS_IMPURE=1`.
- CI guidance: prefer pure evaluation in CI or when you need strictly reproducible builds; expect Emacs to rebuild if inputs changed or the stored path is missing.

### Adding New Host/User
1. `nix run .#add-host -- --hostname HOST --user USER`
2. Configure host-specific settings in generated config
3. Test with `nix run .#configure-user -- --dry-run`
4. Apply with `nix run .#configure-user`

### Shell Customization
1. Edit appropriate shell config in `modules/`
2. Add aliases/functions to shell-specific sections
3. PATH changes go in `modules/path-config.nix`
4. Rebuild with `ns`

## Security Considerations

- Secrets are encrypted at rest (agenix) or stored securely (1Password/pass)
- SSH keys managed separately from repository
- Work/personal credential isolation
- Automatic sensitive data sanitization scripts available

# Agent Rules


# Defensive Programming Rule: Multiple Detection Methods for AI Agents

## Core Principle
**When building shell integrations or subprocess communication systems, never rely on a single detection method for
critical decisions. Always implement multiple, independent verification mechanisms.**

## The Problem Pattern
AI agents often encounter situations where:
- Environment variables don't propagate across process boundaries.
- Subprocess contexts (e.g., during a Nix build) differ from the parent shell's context.
- Integration environments behave differently than isolated test environments.
- Single points of failure cause cascading system failures, like a script terminating the shell it runs in.

## The Multiple Detection Methods Rule

### 1. **Layer Detection Methods by Reliability**
Implement detection in order of decreasing reliability, combining methods from different categories.

-   **Layer 1: Direct Environment Signals:** Most reliable *when present*, but often fail to propagate.
-   **Layer 2: Process-Based Detection:** Reliable and system-wide, but requires knowable process names.
-   **Layer 3: Context-Based Detection:** Good for determining *how* a script is being run (e.g., from a specific
    parent).
-   **Layer 4: File-Based Signaling:** The most universal method; works across all contexts but can be slower and
    requires cleanup.

### 2. **Implement Redundant Signaling**
When a critical process starts, it should signal its state through multiple channels. When it ends, it **must** clean up
all signals.

```bash
# BASH: When starting a critical process, signal through multiple channels
critical_operation_start() {
    # Environment variable (for immediate subprocesses)
    export CRITICAL_OPERATION="true"
    
    # File-based lock (for cross-process communication)
    touch "/tmp/critical_operation.lock"
    echo $$ > "/tmp/critical_operation.pid"
}

critical_operation_end() {
    # Clean up all signals
    unset CRITICAL_OPERATION
    rm -f "/tmp/critical_operation.lock" "/tmp/critical_operation.pid"
}
```

### 3. **Design Detection Functions with Fallback Logic**
Create detection functions that try multiple methods and make a decision based on a **confidence score** rather than a
single binary check.

--- 

## Nushell-Specific Examples

Nushell's structured data and environment handling provide powerful tools for implementing this rule.

### Nushell: Redundant Signaling

```nushell
# When starting a critical process, signal through multiple channels
def "start-critical-op" [] {
    # Environment variable (for immediate subprocesses)
    $env.CRITICAL_OPERATION = "true"
    
    # File-based lock (for cross-process communication)
    touch /tmp/critical_operation.lock
    
    # PID file for more robust process checking
    (pueue status | where status == "running" | get id | last) | save --force /tmp/critical_operation.pid
}

def "end-critical-op" [] {
    # Clean up all signals
    hide-env CRITICAL_OPERATION
    rm /tmp/critical_operation.lock
    rm /tmp/critical_operation.pid
}
```

### Nushell: Multi-Method Detection Function
This function combines multiple detection layers and returns a boolean based on a confidence score.

```nushell
def "is-system-busy" [] {
    mut $confidence_level = 0
    mut $detection_reasons = []

    # Method 1: Environment variables (Confidence: 3)
    if ($env.CRITICAL_OPERATION? | default "") == "true" {
        $confidence_level = $confidence_level + 3
        $detection_reasons = $detection_reasons | append "env_var"
    }

    # Method 2: Process detection (Confidence: 4)
    # Check for Nix, Home Manager, or darwin-rebuild processes
    let active_build_procs = (sys | where name =~ "nix" or name =~ "home-manager" or name =~ "darwin-rebuild" | length)
    if $active_build_procs > 0 {
        $confidence_level = $confidence_level + 4
        $detection_reasons = $detection_reasons | append "process_detection"
    }

    # Method 3: File-based detection (Confidence: 2)
    if ("/tmp/critical_operation.lock" | path exists) {
        $confidence_level = $confidence_level + 2
        $detection_reasons = $detection_reasons | append "file_lock"
    }

    # --- Decision with Logging ---
    # If confidence is 3 or more, we assume the system is busy.
    if $confidence_level >= 3 {
        # Log to stderr so output can be piped
        print -e $"System busy detected (confidence: ($confidence_level), methods: ($detection_reasons | str join ', '))"
        return true
    } else {
        return false
    }
}
```

### Nushell: Environment Variable Propagation
Nushell's `with-env` is the correct way to handle environment variable propagation for subprocesses.

```nushell
# Explicitly pass critical variables to an external script
def "run-sub-script" [] {
    with-env {
        CRITICAL_VAR: ($env.CRITICAL_VAR? | default ""),
        SAFE_MODE: "1" # Always enable safe mode for subprocesses
    } {
        ^external-script.sh
    }
}
```

--- 

## General Application Patterns for AI Agents

1.  **Always implement at least 2-3 detection methods** from different layers for any critical decision.
2.  **Test detection methods in isolation and in their full integration context.** This is crucial for catching
    propagation issues.
3.  **Log which detection methods triggered** to make debugging easier.
4.  **Use confidence levels** rather than simple binary `if/else` checks for more robust decisions.
5.  **Ensure cleanup of all signals** (e.g., lock files) when operations complete or fail.
6.  **Document the detection hierarchy** so it is clear why certain methods are weighted more heavily.

## Key Takeaway for AI Agents

**When integrating with complex systems, always assume that your first, most obvious detection method will fail in some
contexts. Build redundancy and fallback logic from the start, not as an afterthought.**

This approach transforms brittle integrations into robust systems that gracefully handle the unpredictable nature of
subprocess communication and environment inheritance.

---

*This rule emerged from debugging a complex Nushell/Zellij/Nix integration where single-method detection failed across
process boundaries, causing system instability.*

# Nix created scripts

Make sure that when modifying nix files, you use correct nix syntax. For the case when adding scripts in a specific
programming/scripting language (like bash, python, nushell, etc.) make sure to correctly escape special characters so
that the script can be embedded in nix files.

Nix String Literal Escaping Rules
=================================

For Double-Quoted Strings ("..."):
---------------------------------

1. To escape a double quote: \" Example: "\"" produces "

2. To escape a backslash: \\ Example: "\\" produces \

3. To escape dollar-curly (${): \${ Example: "\${" produces ${ Note: This prevents string interpolation

4. Special characters:
   - Newline: \n
   - Carriage return: \r
   - Tab: \t

5. Double-dollar-curly (${) can be written literally: Example: "$${" produces ${

For Indented Strings (''...''):
-------------------------------

1. To escape $ (dollar): ''$ Example: '' ''$ '' produces "$\n"

2. To escape '' (double single quote): ' Example: '' ''' '' produces "''\n"

3. Special characters:
   - Linefeed: ''\n
   - Carriage return: ''\r
   - Tab: ''\t

4. To escape any other character: ''\

5. To write dollar-curly (${) literally: ''${ Example: '' echo ''${PATH} '' produces "echo ${PATH}\n" Note: This is
   different from double-quoted strings!

6. Double-dollar-curly ($${) can be written literally: Example: '' $${ '' produces "$\${\n"

Key Points for Embedded Scripts:
-------------------------------

- In double-quoted strings: Use \${ to prevent interpolation
- In indented strings: Use ''${ to prevent interpolation
- @ symbol in bash arrays like ${ARRAY[@]} does NOT need escaping
- Only $ needs escaping when it precedes { for interpolation

Common Patterns:
---------------

1. Bash array expansion in double-quoted Nix string: "\${ARRAY[@]}" # Escapes the $ to prevent Nix interpolation

2. Bash array expansion in indented Nix string: '' for item in "\${ARRAY[@]}"; do echo $item done ''

3. Bash variable in double-quoted Nix string: "\$HOME" # Escapes $ to prevent Nix interpolation

4. Bash variable in indented Nix string: '' echo \$HOME ''
   

# Location for external bash/zsh//nushell shellscripts that are expected to be triggered by Raycast hotkeys

When nix creates an external script that will be triggered by a Raycast hotkey, put them at ~/.local/share/bin

This rule does not apply to other kinds of files like plist files, that are expected to be in the macOS standard
directories. For all the plist files created by nix, create them at the user level, so that there are not problems with
SIP (System Integrity Protection).


# Lisp-like languages validation command line tools

Use the following command line tool in my path to validate and fix files after changes in elisp code. Note that this
rule doesn't apply to other programming languages like nix, java, etc. It's only useful for Emacs Lisp code.

elisp-formatter.js --help

🔧 Elisp Formatter - Advanced S-expression formatting with auto-repair

This tool formats Elisp files using Parinfer and can automatically repair structural issues like missing parentheses or
unbalanced expressions.

Usage: elisp-formatter [options] [command]

Check and format Elisp S-expressions using Parinfer with auto-repair capabilities

Options: -V, --version output the version number -h, --help display help for command

Commands: check <file> Check if S-expressions are balanced (validation only, no formatting) indent [options] <file>
  Format using Indent Mode (indentation drives structure, aggressive paren fixing) paren [options] <file> Format using
  Paren Mode (preserves parentheses, adjusts indentation) smart [options] <file> Format using Smart Mode (intelligent
  hybrid of indent and paren modes) elisp [options] <file> Format specifically for Elisp with custom rules (RECOMMENDED
  for .el files) batch [options] <directory> Process all .el files in directory (recursively scans subdirectories) help
  [command] display help for command

📖 FORMATTING MODES: • check - Validate S-expression balance (no changes made) • indent - Indentation drives structure
  (aggressive paren fixing) • paren - Parentheses drive structure (preserves existing parens) • smart - Intelligent
  hybrid mode (recommended for most cases) • elisp - Smart mode + Elisp-specific formatting rules (recommended) •
  batch - Process multiple .el files in a directory

🔧 AUTO-REPAIR FEATURES: The formatter can automatically fix common structural issues: • Missing closing parentheses •
  Unbalanced expressions • Malformed S-expressions

  Auto-repair is enabled by default. Use --no-auto-repair to disable.

📋 USAGE EXAMPLES:

  Basic formatting: elisp-formatter elisp my-config.el elisp-formatter smart my-config.el

  Check without modifying: elisp-formatter elisp my-config.el --check elisp-formatter check my-config.el

  Output to stdout: elisp-formatter elisp my-config.el --stdout

  Disable auto-repair: elisp-formatter elisp my-config.el --no-auto-repair

  Process entire directory: elisp-formatter batch ./config elisp-formatter batch ./config --mode elisp elisp-formatter
    batch ./config --check

  Advanced batch processing: elisp-formatter batch ./config --mode smart --no-auto-repair elisp-formatter batch ./config
    --stdout

🚀 RECOMMENDED WORKFLOWS:

  For Doom Emacs configs: elisp-formatter batch ~/.doom.d/config --mode elisp

  Quick validation: elisp-formatter batch . --check

  Safe preview before changes: elisp-formatter batch . --stdout | less

💡 TIP: Use 'elisp' mode for best results with Emacs Lisp files. It includes specialized formatting rules for Elisp
     constructs.

Always check for correctness after doing changes.



# Emacs Lisp Regex Escaping Guidelines

## Context
When writing or editing Emacs Lisp (`.el`) files that contain regular expressions within string literals, follow these
escaping rules to prevent `invalid-regexp "Unmatched ) or \\"` errors.

## Core Principle
In Emacs Lisp string literals, you need **exactly one level** of backslash escaping for regex special characters.

## Correct Escaping Patterns

| Regex Element | **CORRECT** in Emacs Lisp String | **WRONG** (Over-escaped) | Purpose |
|---------------|-----------------------------------|--------------------------|---------|
| Literal dot | `\\.` | `\\\\.` | Match a literal period |
| Capturing group | `\\(pattern\\)` | `\\\\(pattern\\\\)` | Create capture group |
| Alternation | `\\|` | `\\\\|` | OR operator |
| Word boundary | `\\b` | `\\\\b` | Word boundary |
| End of string | `\\'` | `\\\\'` | End of string anchor |
| Literal backslash | `\\\\` | `\\\\\\\\` | Match literal `\` |

## Common File Mode Patterns

```elisp
;; ✅ CORRECT: File extension matching
(add-to-list 'auto-mode-alist '("\\.json$" . json-mode))
(string-match-p "\\.(el\\|py\\|js)$" filename)

;; ❌ WRONG: Over-escaped
(add-to-list 'auto-mode-alist '("\\\\.json$" . json-mode))
(string-match-p "\\\\.(el\\\\|py\\\\|js)$" filename)
```

## Buffer Name/Path Patterns

```elisp
;; ✅ CORRECT: Buffer name matching
(string-match-p "^\\*Ollama\\*$" buffer-name)
(string-match-p "^\\*cider-repl" buffer-name)

;; ❌ WRONG: Over-escaped  
(string-match-p "^\\\\*Ollama\\\\*$" buffer-name)
(string-match-p "^\\\\*cider-repl" buffer-name)
```

## Popup Rule Patterns

```elisp
;; ✅ CORRECT: Doom popup rules
(set-popup-rule! "^\\*tabnine-chat\\*$" :side 'right)
(set-popup-rule! "^\\*xwidget-webkit:.*\\.html\\*$" :side 'right)

;; ❌ WRONG: Over-escaped
(set-popup-rule! "^\\\\*tabnine-chat\\\\*$" :side 'right)
(set-popup-rule! "^\\\\*xwidget-webkit:.*\\\\.html\\\\*$" :side 'right)
```

## Search Patterns

```elisp
;; ✅ CORRECT: Search patterns
(re-search-forward "^nREPL server started on port \\([0-9]+\\)$" nil t)
(string-match "gradle-\\([0-9]+\\.[0-9]+\\(\\.[0-9]+\\)?\\)" version)

;; ❌ WRONG: Over-escaped
(re-search-forward "^nREPL server started on port \\\\([0-9]+\\\\)$" nil t)
(string-match "gradle-\\\\([0-9]+\\\\.[0-9]+\\\\(\\\\.[0-9]+\\\\)?\\\\)" version)
```

## Validation Method

Before using any regex pattern in Emacs Lisp:

1. **Test the pattern** in isolation:
   ```elisp
   (string-match-p "your-pattern-here" "test-string")
   ```

2. **Check for syntax errors**:
   ```bash
   emacs --batch --eval "(string-match \"your-pattern\" \"test\")" 2>&1
   ```

3. **Look for these error indicators**:
   - `invalid-regexp`
   - `Unmatched ) or \\`
   - `File mode specification error`

## High-Risk Locations

Pay special attention to regex patterns in:

- `auto-mode-alist` entries
- `magic-mode-alist` entries  
- `interpreter-mode-alist` entries
- `set-popup-rule!` patterns (Doom Emacs)
- `string-match-p` calls
- `re-search-forward` patterns
- `re-search-backward` patterns
- File extension checks
- Buffer name matching
- Path/directory matching

## Common Error Scenarios

### File Mode Specification Errors
These errors typically occur when:
- Loading files with problematic `auto-mode-alist` patterns
- Popup rules with invalid regex patterns
- Mode detection functions with over-escaped patterns

### Search Function Errors
These occur in:
- Text processing functions
- Project cleanup utilities  
- Credential parsing functions
- Build tool integration

## Quick Fix Rule

If you see an `invalid-regexp` error:

1. **Identify the error source**: Look for the file mentioned in the error
2. **Find the problematic regex**: Search for string literals containing `\\\\`
3. **Apply the fix**: Remove one level of backslash escaping from regex special characters
4. **Test the pattern**: Use `(string-match-p "fixed-pattern" "test-string")`
5. **Restart Emacs**: Clear cached bytecode with a fresh restart

## Example Fixes

### File Extension Matching
```elisp
;; Before (causing error):
(string-match-p "\\\\.(el\\\\|nix\\\\|sh\\\\|py\\\\|js\\\\|ts\\\\)$" filename)

;; After (fixed):  
(string-match-p "\\.(el\\|nix\\|sh\\|py\\|js\\|ts)$" filename)
```

### Buffer Name Matching  
```elisp ;; Before (causing error): (string-match-p "^\\\\*Ollama\\\\*$" buffer-name)

;; After (fixed):
(string-match-p "^\\*Ollama\\*$" buffer-name)
```

### Capture Groups
```elisp
;; Before (causing error):
(re-search-forward "\\\"\\\\([^\\\"]+\\\\)\\\"" nil t)

;; After (fixed):
(re-search-forward "\"\\([^\"]+\\)\"" nil t)
```

## Memory Aid

**Remember**: In Emacs Lisp strings, `\\(` becomes `\(` in the actual regex. If you have `\\\\(`, it becomes `\\(` which
is invalid regex syntax.

The rule is simple: **One backslash to escape in the string, one backslash for the regex.**

## Testing Your Patterns

Create a simple test function to validate patterns:

```elisp
(defun test-regex-pattern (pattern test-string)
  "Test PATTERN against TEST-STRING and report results."
  (condition-case err
      (progn
        (string-match-p pattern test-string)
        (message "✅ Pattern '%s' is valid" pattern))
    (error 
     (message "❌ Pattern '%s' failed: %s" pattern (error-message-string err)))))

;; Usage:
(test-regex-pattern "\\.(el\\|py)$" "test.el")
```

---

**Created**: 2025-08-21
**Context**: Fixed `invalid-regexp "Unmatched ) or \\"` error in Doom Emacs configuration  
**Last Issue**: `my-enhanced-auth-config.el` line 146 - file extension matching pattern



# Prefer faster (available) rust based command line utilities than classic ones

fd instead of find rg instead of grep etc


# lombok configuration in a Java project

In a Java project (with a pom.xml, or a gradle build), respect the lombok.config file. In most of the cases, it will
have:

```
lombok.accessors.chain=true
lombok.equalsAndHashCode.callSuper=call

# Section 7.2 of Checker Framework manual
lombok.addLombokGeneratedAnnotation = true

# Best practice
lombok.addNullAnnotations=checkerframework

lombok.log.fieldName=logger
```

Respect the name for the logger. Also, in a inheritance of classes or a class implementing an interface, prefer the most
specific logger in the subclass (respect the more specific lombok annotation of @Slf4j).


# Stow should put resulting script targets in ~/.local/share/bin

Stow should put resulting script targets in ~/.local/share/bin, not in ~/.local/bin


# Currently installed version of macOS

My OS is macOS. I am currently on macOS 26 Tahoe, which is a very recent version of the OS, and is the successor of
Sequoia.

There is no error in the version number of the system.


# NordVPN

There is no nordvpn cli available in my system. Do not search for one nor try to install it. Do not try to find any,
anywhere. There are no alternative paths, because there is no nordvpn cli.


# Emojis and other unicode characters in nix files.

When there's a need to use/embed unicode or emojis in my nix configuration files, make sure to correctly encode them
with escaped ASCII strings using the \UXXXX format. When creating an embedded bash script in nix, consider correct
escaping that works for bash, in the context of an embedded nix script.


# ns and nb aliases to build-switch and build (respectively) my ~/darwin-configuration (nix based).

Use my custom aliases with verbose output
- To build my nix configuration: `nb -v`
- To build-switch my nix configuration: `ns -v`


# Applying diffs/patches or changes to programming files

When applying diffs, make sure they're complete when applying them. Specially when dealing with elisp code, or
S-expressions, make sure the final code is correct and parens are properly balanced. Verify that after commenting a
section of code, proper syntax, forms and parens exist in the final code.

Do not insert intermediate comments between parens (if comments are added, put them in their own line). This would
probably make the paren balancing check easier.


# Correct characters for comments on different programming languages

Not all programming languages use the same characters to comment out code. Respect the rules for each language. For
elisp, it should be ; or several ; in a row.


# Terminal and GUI Environments for Emacs

I expect emacs to work both on terminal and GUI Emacs (normally or connecting emacsclient to the emacs daemon), and if
this is not possible, on GUI Emacs at least. I use ghostty terminal. Emacs terminal should work reliably for ghostty
terminal.


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
