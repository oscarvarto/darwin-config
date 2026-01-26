#!/usr/bin/env nu

# 1Password CLI helper for secrets - Nushell version
# Provides better error handling and structured data output

# Get a secret from 1Password
def "1p get" [vault_item_field: string] {
    let op_path = $"op://($vault_item_field)"
    
    try {
        op read $op_path
    } catch {
        error make {
            msg: $"❌ Failed to read from 1Password: ($vault_item_field)"
            help: "💡 Try: op signin"
        }
    }
}

# Set environment variable from 1Password
def "1p env" [var_name: string, vault_item_field: string] {
    let secret_value = try {
        1p get $vault_item_field
    } catch {
        return
    }
    
    # Set the environment variable
    load-env {$var_name: $secret_value}
    print $"✅ Exported ($var_name) from 1Password"
}

# Load multiple secrets into environment
def "1p load-env" [secrets: record] {
    for entry in ($secrets | transpose key value) {
        try {
            1p env $entry.key $entry.value
        } catch {
            print $"⚠️  Failed to load ($entry.key)"
        }
    }
}

# Check 1Password CLI status
def "1p status" [] {
    let has_op = try {
        which op | is-not-empty
    } catch {
        false
    }
    
    if not $has_op {
        print "❌ 1Password CLI not found"
        return false
    }
    
    let signed_in = try {
        op account get | is-not-empty
    } catch {
        false
    }
    
    if $signed_in {
        print "✅ 1Password CLI ready"
        let account_info = try {
            op account get | from json
        } catch {
            {}
        }
        
        if not ($account_info | is-empty) {
            print $"📧 Account: ($account_info.email? | default 'Unknown')"
            print $"🏢 Domain: ($account_info.domain? | default 'Unknown')"
        }
        return true
    } else {
        print "❌ Not signed in to 1Password"
        print "💡 Run: op signin"
        return false
    }
}

# List available vaults
def "1p vaults" [] {
    try {
        op vault list --format json | from json
    } catch {
        error make {
            msg: "Failed to list vaults"
            help: "Ensure you're signed in: op signin"
        }
    }
}

# Show help information
def "1p help" [] {
    print "🔑 1Password Git Helper - Nushell Edition"
    print ""
    print "Commands:"
    print "  1p get <vault/item/field>        - Get a secret value"
    print "  1p env <VAR_NAME> <vault/item/field> - Set environment variable"
    print "  1p load-env <record>             - Load multiple secrets to environment"
    print "  1p status                        - Check 1Password CLI status"
    print "  1p vaults                        - List available vaults"
    print "  1p help                          - Show this help"
    print ""
    print "Examples:"
    print "  # Get a single secret"
    print "  let api_key = (1p get 'MyVault/API/key')"
    print ""
    print "  # Set environment variable"
    print "  1p env API_KEY 'MyVault/API/key'"
    print ""
    print "  # Load multiple secrets"
    print "  1p load-env {"
    print "    API_KEY: 'MyVault/API/key'"
    print "    DB_PASSWORD: 'MyVault/Database/password'"
    print "    OAUTH_SECRET: 'MyVault/OAuth/secret'"
    print "  }"
    print ""
    print "  # Check status"
    print "  1p status"
    print ""
    print "  # List vaults"
    print "  1p vaults | select name id"
}

def main [action?: string, ...args] {
    match $action {
        "get" => {
            if ($args | length) < 1 {
                print "Usage: 1p get <vault/item/field>"
                exit 1
            }
            1p get $args.0
        }
        "env" => {
            if ($args | length) < 2 {
                print "Usage: 1p env <VAR_NAME> <vault/item/field>"
                exit 1
            }
            1p env $args.0 $args.1
        }
        "load-env" => {
            print "Interactive mode for loading multiple environment variables:"
            print "Create a record with variable names and their 1Password paths"
            print "Example: {API_KEY: 'MyVault/API/key', DB_PASS: 'MyVault/DB/password'}"
        }
        "status" => {
            1p status
        }
        "vaults" => {
            1p vaults
        }
        "help" | null => {
            1p help
        }
        _ => {
            print $"Unknown command: ($action)"
            1p help
            exit 1
        }
    }
}
