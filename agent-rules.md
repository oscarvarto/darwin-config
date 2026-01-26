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

  For custom Emacs configs: elisp-formatter batch ~/.emacs.d --mode elisp

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

There is no error in the version number of the system. Apple decided to assign this number to reflect a big change in
the OS, and simplify the versioning across its products (iOS, macOS, WatchOS, etc.).


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
