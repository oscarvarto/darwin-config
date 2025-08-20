#!/usr/bin/env nu

# Script to update work git config with email from 1Password - Nushell version
# Better error handling and structured configuration management

def main [] {
    let user = $env.USER? | default "oscarvarto"
    let config_dir = $"($env.HOME)/.local/share/git"
    let config_file = $"($config_dir)/config-work"
    
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
            print "💡 Install via nixos-config and sign in with: op signin"
            "YOUR-WORK-EMAIL@company.com"
        } else {
            let signed_in = try { op account get | is-not-empty } catch { false }
            if not $signed_in {
                print "⚠️ 1Password CLI not signed in. Using placeholder email."
                print "💡 Sign in with: op signin"
                "YOUR-WORK-EMAIL@company.com"
            } else {
                # Try to read work email from 1Password
                try {
                    op read "op://Work/CompanyName/email"
                } catch {
                    print "⚠️ Could not read work email from 1Password. Using placeholder."
                    print "💡 Create 1Password item: Work/CompanyName with email field"
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
    name = Oscar Vargas Torres
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
            print "1. Create a new item in your 'Work' vault"
            print "2. Title: 'CompanyName' (replace with your company)"
            print "3. Add a field named 'email' with your work email"
            print "4. Run this script again"
        } else {
            print ""
            print "🎯 Work git configuration active for directories matching: ~/ir/**"
            print "🔧 Test with: cd ~/ir/some-repo && git config --get user.email"
        }
    } catch {
        print $"❌ Failed to write config file: ($config_file)"
        exit 1
    }
}
