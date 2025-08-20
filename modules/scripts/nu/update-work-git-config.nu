#!/usr/bin/env nu

# Script to update work git config with email from 1Password - Nushell version
# Uses configurable work settings to avoid hardcoded company references

def main [] {
    let user = $env.USER? | default "your_user"
    let config_dir = $"($env.HOME)/.local/share/git"
    let config_file = $"($config_dir)/config-work"
    
    # Get work configuration from environment or use defaults
    let company_name = $env.WORK_COMPANY_NAME? | default "CompanyName"
    let op_vault = $env.WORK_OP_VAULT? | default "Work"
    let op_item = $env.WORK_OP_ITEM? | default $company_name
    let work_dir_pattern = $env.WORK_GIT_DIR_PATTERN? | default "~/work/**"
    
    # Ensure directory exists
    try {
        mkdir $config_dir
    } catch {
        # Directory might already exist, which is fine
    }
    
    # Try to get work email from 1Password, fallback to placeholder
    let work_email = try {
        # Check if 1Password CLI is available and signed in
        let has_op = try { which op | is-not-empty } catch { false }
        if not $has_op {
            print "⚠️ 1Password CLI not available. Using placeholder email."
            print "💡 Install via darwin-config and sign in with: op signin"
            "YOUR-WORK-EMAIL@company.com"
        } else {
            let signed_in = try { op account get | is-not-empty } catch { false }
            if not $signed_in {
                print "⚠️ 1Password CLI not signed in. Using placeholder email."
                print "💡 Sign in with: op signin"
                "YOUR-WORK-EMAIL@company.com"
            } else {
                # Try to read work email from 1Password using configurable settings
                try {
                    op read $"op://($op_vault)/($op_item)/email"
                } catch {
                    print $"⚠️ Could not read work email from 1Password. Using placeholder."
                    print $"💡 Create 1Password item: ($op_vault)/($op_item) with email field"
                    "YOUR-WORK-EMAIL@company.com"
                }
            }
        }
    } catch {
        print "⚠️ Error accessing 1Password. Using placeholder email."
        "YOUR-WORK-EMAIL@company.com"
    }
    
    # Create the git config content
    let config_content = $"[user]
    name = Your Name
    email = ($work_email)
"
    
    # Write the config file
    try {
        $config_content | save --force $config_file
        print $"✅ Updated work git config with email: ($work_email)"
        
        # Provide helpful info about usage
        if $work_email == "YOUR-WORK-EMAIL@company.com" {
            print ""
            print "📋 To set up 1Password integration:"
            print $"1. Create a new item in your '($op_vault)' vault"
            print $"2. Title: '($op_item)' (your company name)"
            print "3. Add a field named 'email' with your work email"
            print "4. Run this script again"
        } else {
            print ""
            print $"🎯 Work git configuration active for directories matching: ($work_dir_pattern)"
            print $"🔧 Test with: cd (echo $work_dir_pattern | str replace '/**' '/some-repo') && git config --get user.email"
        }
    } catch {
        print $"❌ Failed to write config file: ($config_file)"
        exit 1
    }
}
