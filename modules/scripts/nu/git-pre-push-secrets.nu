#!/usr/bin/env nu

# Pre-push hook to prevent pushing secrets to remote master
# Scans commits being pushed to refs/heads/master

def main [remote_name?: string, remote_url?: string] {
    # ANSI color constants
    let RED = "\u{001b}[0;31m"
    let GREEN = "\u{001b}[0;32m"
    let YELLOW = "\u{001b}[1;33m"
    let NC = "\u{001b}[0m"

    let stdin_lines = try { $in | lines } catch { [] }
    if ($stdin_lines | is-empty) {
        exit 0
    }

    # Secret detection patterns (kept in sync with pre-commit hook)
    let patterns = [
        { name: "AWS Access Key", pattern: "AKIA[0-9A-Z]{16}", exclusions: ["AKIAIOSFODNN7EXAMPLE", "AKIAI44QH8DHBEXAMPLE"] }
        { name: "OpenAI API Key", pattern: "sk-[a-zA-Z0-9]{48}", exclusions: ["sk-1234567890abcdef1234567890abcdef12345678"] }
        { name: "GitHub Token (Personal Access)", pattern: "ghp_[A-Za-z0-9]{36}", exclusions: [] }
        { name: "GitHub Token (OAuth)", pattern: "gho_[A-Za-z0-9]{36}", exclusions: [] }
        { name: "GitHub Token (User-to-Server)", pattern: "ghu_[A-Za-z0-9]{36}", exclusions: [] }
        { name: "GitHub Token (Server-to-Server)", pattern: "ghs_[A-Za-z0-9]{36}", exclusions: [] }
        { name: "GitHub Token (Refresh)", pattern: "ghr_[A-Za-z0-9]{36}", exclusions: [] }
        {
            name: "Generic API Key Assignment"
            pattern: "api[_-]?key.*[=:].*[a-zA-Z0-9_-]{20,}"
            exclusions: ["your-api-key", "your_api_key", "YOUR_API_KEY", "api-key-here", "<api-key>", "{{api_key}}", "${API_KEY}", "example", "test", "dummy"]
        }
        {
            name: "Generic Secret Assignment"
            pattern: "(secret|password|token).*[=:].*[a-zA-Z0-9_-]{12,}"
            exclusions: ["your-secret", "your-password", "your-token", "password123", "secret123", "<secret>", "{{secret}}", "${SECRET}", "change-me", "changeme", "password", "example", "test", "dummy"]
        }
        {
            name: "JWT Token"
            pattern: "eyJ[A-Za-z0-9_-]+[.][A-Za-z0-9_-]+[.][A-Za-z0-9_-]+"
            exclusions: ["eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"]
        }
        { name: "Private Key (PEM)", pattern: "-----BEGIN (RSA |DSA |EC |OPENSSH |PGP )?PRIVATE KEY-----", exclusions: [] }
        { name: "Slack Token", pattern: "xox[baprs]-[0-9a-zA-Z-]{10,72}", exclusions: [] }
        { name: "Discord Bot Token", pattern: "[A-Za-z0-9]{24}[.][A-Za-z0-9_-]{6}[.][A-Za-z0-9_-]{27}", exclusions: [] }
        { name: "Google API Key", pattern: "AIza[0-9A-Za-z_-]{35}", exclusions: [] }
        { name: "Stripe API Key", pattern: "sk_(live|test)_[0-9a-zA-Z]{24}", exclusions: [] }
        { name: "Twilio API Key", pattern: "SK[0-9a-fA-F]{32}", exclusions: [] }
        { name: "Azure Storage Account Key", pattern: "[a-zA-Z0-9+/]{88}==", exclusions: [] }
    ]

    let extensions = [".js" ".ts" ".py" ".java" ".scala" ".clj" ".cs" ".json" ".yaml" ".yml" ".toml" ".env" ".sh" ".bash" ".fish" ".nix"]

    mut found_secrets = false

    for line in $stdin_lines {
        let parts = ($line | split row " " | where { |p| $p | str length > 0 })
        if ($parts | length) < 4 {
            continue
        }
        let local_sha = $parts.1
        let remote_ref = $parts.2
        let remote_sha = $parts.3

        if not ($remote_ref | str ends-with "refs/heads/master") {
            continue
        }

        let zero = "0000000000000000000000000000000000000000"
        let range = if $remote_sha == $zero { $local_sha } else { $"($remote_sha)..($local_sha)" }

        print $"($YELLOW)🔍 Scanning push to master for secrets...($NC)"

        let files = try {
            git diff --name-only $range
            | lines
            | where { |file|
                $extensions | any { |ext| $file | str ends-with $ext }
            }
        } catch {
            []
        }

        for file in $files {
            let file_content = try {
                git show $"($local_sha):($file)"
            } catch {
                continue
            }

            for pattern_info in $patterns {
                let potential_matches = try {
                    $file_content | find --regex $pattern_info.pattern
                } catch {
                    []
                }

                let actual_matches = if ($potential_matches | is-empty) {
                    []
                } else {
                    $potential_matches | where { |match|
                        not ($pattern_info.exclusions | any { |exclusion| $match | str contains $exclusion })
                    }
                }

                if not ($actual_matches | is-empty) {
                    print $"($RED)❌ Potential ($pattern_info.name) found in ($file)($NC)"
                    for match in ($actual_matches | first 3) {
                        let preview = if ($match | str length) > 20 {
                            ($match | str substring 0..20) + "..."
                        } else {
                            $match
                        }
                        print $"   ($YELLOW)Context: ($preview)($NC)"
                    }
                    $found_secrets = true
                }
            }
        }
    }

    if $found_secrets {
        print $"($RED)\n🚫 PUSH BLOCKED: Potential secrets detected!($NC)"
        print $"($YELLOW)💡 Use 1Password CLI instead:($NC)"
        print $"($YELLOW)   $env.API_KEY = (op read 'op://vault/item/field')($NC)"
        print ""
        print $"($YELLOW)🔧 To bypass \(use with caution\): git push --no-verify($NC)"
        exit 1
    }

    print $"($GREEN)✅ No secrets detected for master push($NC)"
    exit 0
}
