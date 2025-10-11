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
