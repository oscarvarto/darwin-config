# Nushell Integration Debugging Rules

## Context
These rules were developed after debugging a complex issue where the `ns` command in Nushell was causing Zellij sessions to quit unexpectedly during Nix builds. The debugging process revealed multiple layers of complexity that are common in Nushell integrations.

## Core Debugging Methodology

### 1. **Always Start with String Interpolation Issues**
**Rule**: When Nushell reports "Command not found" errors for non-existent commands, suspect string interpolation problems FIRST.

**Why**: Nushell's string interpolation `$"..."` treats parentheses as command substitution by default.

**Common Patterns**:
```nushell
# ❌ WRONG - Nushell tries to execute `zellij-safe` as a command
print $"Running directly (zellij-safe mode)..."

# ✅ CORRECT - Escape parentheses for literal text
print $"Running directly \\(zellij-safe mode\\)..."
```

**Debugging Steps**:
1. Look for unescaped parentheses in string interpolation
2. Check for special characters that might be interpreted as commands
3. Test string interpolation in isolation before complex logic

### 2. **Trace the Full Process Chain**
**Rule**: In complex system integrations, always map out the COMPLETE process execution chain.

**Our Case Study**:
```
User runs `ns` in Nushell 
→ `ns` function calls Nix build
→ Nix calls darwin-rebuild
→ darwin-rebuild calls home-manager
→ home-manager runs activation scripts
→ (Legacy) Activation script called theme-switcher
→ Theme-switcher kills Zellij sessions (❌ UNEXPECTED)
→ `ns` process dies because its shell session was terminated
```

**Debugging Approach**:
1. **Map the entire chain**: Don't assume the problem is in the obvious place
2. **Identify all subprocesses**: Use `pgrep`, `ps`, or process monitoring
3. **Check environment inheritance**: Variables may not propagate through subprocess boundaries
4. **Look for side effects**: Scripts may have unintended consequences on parent processes

### 3. **Environment Variables Don't Always Propagate**
**Rule**: Environment variables set in shell functions may not reach subprocesses, especially across different execution contexts (Nix builds, activation scripts, etc.).

**Problems Encountered**:
```nushell
# In `ns` function:
$env.GHOSTTY_SAFE_MODE = "1"
$env.NUSHELL_NIX_BUILD = "true"

# But subprocesses spawned by Nix build don't see these variables!
```

**Solutions**:
1. **Explicit propagation**: Pass variables explicitly to subprocess calls
2. **Multiple detection methods**: Don't rely only on environment variables
3. **Process-based detection**: Use `pgrep` to detect ongoing processes
4. **File-based signaling**: Create temporary files as signals between processes

### 4. **Bash vs. Nushell Context Switching**
**Rule**: When Nushell calls external scripts (especially bash scripts), be aware of context switching issues.

**Common Issues**:
- `local` variables only work inside bash functions, not at script level
- Environment variable syntax differs between shells
- String escaping rules are different

**Best Practices**:
```bash
# ❌ WRONG - `local` outside function
local build_in_progress=false

# ✅ CORRECT - Regular variable
build_in_progress=false

# ❌ WRONG - Assuming Nushell environment variables
if [[ "$NUSHELL_VAR" == "true" ]]; then

# ✅ CORRECT - Defensive environment variable checking
if [[ "${NUSHELL_VAR:-}" == "true" ]]; then
```

### 5. **Test in Isolation vs. Integration Context**
**Rule**: Issues that don't appear in isolation may only manifest in full integration context.

**Our Experience**:
- String interpolation worked fine in command-line tests
- Only failed when called through the full Nix build chain
- Environment and subprocess context matters enormously

**Testing Strategy**:
1. **Isolated testing**: Test individual components first
2. **Integration testing**: Test the full chain in realistic conditions
3. **Subprocess simulation**: Test how components behave when called by other processes
4. **Environment simulation**: Test with different environment variable states

## Specific Nushell-Related Patterns

### String Interpolation Safety Rules
```nushell
# Always escape special characters in user-facing text
$"Processing \\(advanced mode\\) files..."    # ✅ CORRECT
$"Processing (advanced mode) files..."        # ❌ WRONG

# For dynamic content, validate it doesn't contain shell metacharacters
let safe_text = ($user_input | str replace "(" "\\(" | str replace ")" "\\)")
```

### Environment Variable Best Practices
```nushell
# Always provide defaults for environment variables
$env.MY_VAR = ($env.MY_VAR? | default "safe_default")

# When calling external processes, explicitly pass critical variables
with-env {
    CRITICAL_VAR: $env.CRITICAL_VAR
    BUILD_MODE: "safe"
} {
    ^external-script
}
```

### Subprocess Safety Patterns
```nushell
# Before calling external processes that might affect current session
$env.SAFE_MODE = "1"
$env.CURRENT_SESSION = ($env.ZELLIJ_SESSION_NAME? | default "")

# Call with explicit environment
^external-script
```

## Debugging Checklist for Complex Nushell Issues

### Immediate Investigation
- [ ] Check for unescaped special characters in string interpolation
- [ ] Verify the actual error (look beyond surface symptoms)
- [ ] Test the problematic code in isolation
- [ ] Check for environment variable propagation issues

### Deep Investigation  
- [ ] Map out the complete process execution chain
- [ ] Identify all subprocess calls and their contexts
- [ ] Check if subprocesses are affecting parent processes unexpectedly
- [ ] Verify environment variable inheritance across process boundaries
- [ ] Look for bash/nushell context switching issues

### System Integration Issues
- [ ] Test the scenario in the actual integration environment
- [ ] Check for race conditions between processes
- [ ] Verify that safe mode flags and detection work correctly
- [ ] Ensure cleanup and error handling don't affect parent processes

### Validation
- [ ] Test the fix in both isolated and integration contexts
- [ ] Verify that the fix doesn't introduce new issues
- [ ] Check that error handling is robust
- [ ] Ensure the solution is maintainable and understandable

## Anti-Patterns to Avoid

1. **Assuming isolation**: Don't assume issues are isolated to the immediate code
2. **Over-relying on environment variables**: They don't always propagate as expected
3. **Ignoring subprocess effects**: Subprocesses can kill parent processes
4. **Single-point detection**: Use multiple detection methods for critical decisions
5. **Context switching blindness**: Be aware when moving between shell contexts

## Recovery Patterns

When debugging complex Nushell integration issues:

1. **Start simple**: Isolate and test the most obvious potential issue first
2. **Build complexity gradually**: Add layers back one at a time
3. **Use multiple validation methods**: Don't rely on single points of failure
4. **Add defensive programming**: Handle edge cases and unexpected conditions
5. **Document the full chain**: Understanding the complete flow is crucial for future maintenance

---

*Last updated: 2025-08-23*  
*Based on debugging session: ns command causing Zellij session termination during Nix builds*
