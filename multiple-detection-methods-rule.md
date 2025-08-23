# Defensive Programming Rule: Multiple Detection Methods for AI Agents

## Core Principle
**When building shell integrations or subprocess communication systems, never rely on a single detection method for critical decisions. Always implement multiple, independent verification mechanisms.**

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
-   **Layer 3: Context-Based Detection:** Good for determining *how* a script is being run (e.g., from a specific parent).
-   **Layer 4: File-Based Signaling:** The most universal method; works across all contexts but can be slower and requires cleanup.

### 2. **Implement Redundant Signaling**
When a critical process starts, it should signal its state through multiple channels. When it ends, it **must** clean up all signals.

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
Create detection functions that try multiple methods and make a decision based on a **confidence score** rather than a single binary check.

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
2.  **Test detection methods in isolation and in their full integration context.** This is crucial for catching propagation issues.
3.  **Log which detection methods triggered** to make debugging easier.
4.  **Use confidence levels** rather than simple binary `if/else` checks for more robust decisions.
5.  **Ensure cleanup of all signals** (e.g., lock files) when operations complete or fail.
6.  **Document the detection hierarchy** so it is clear why certain methods are weighted more heavily.

## Key Takeaway for AI Agents

**When integrating with complex systems, always assume that your first, most obvious detection method will fail in some contexts. Build redundancy and fallback logic from the start, not as an afterthought.**

This approach transforms brittle integrations into robust systems that gracefully handle the unpredictable nature of subprocess communication and environment inheritance.

---

*This rule emerged from debugging a complex Nushell/Zellij/Nix integration where single-method detection failed across process boundaries, causing system instability.*

