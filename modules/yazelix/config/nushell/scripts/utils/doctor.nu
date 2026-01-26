#!/usr/bin/env nu
# Yazelix Doctor - Health check utilities

use logging.nu log_to_file

# Check environment variables
export def check_environment_variables [] {
    mut results = []
    
    # Check EDITOR
    if ($env.EDITOR? | is-empty) {
        $results = ($results | append {
            status: "warning"
            message: "EDITOR environment variable not set"
            details: "Some tools may not know which editor to use"
            fix_available: false
        })
    } else {
        $results = ($results | append {
            status: "ok" 
            message: $"EDITOR set to: ($env.EDITOR)"
            details: null
            fix_available: false
        })
    }
    
    $results
}

# Check configuration files
export def check_configuration [] {
    let yazelix_config = "~/.config/yazelix/yazelix.toml"
    let yazelix_legacy = "~/.config/yazelix/yazelix.nix"
    let yazelix_default = "~/.config/yazelix/yazelix_default.toml"
    
    mut results = []
    
    if ($yazelix_config | path expand | path exists) {
        $results = ($results | append {
            status: "ok"
            message: "Using custom yazelix.toml configuration"
            details: ($yazelix_config | path expand)
            fix_available: false
        })
    } else if ($yazelix_legacy | path expand | path exists) {
        $results = ($results | append {
            status: "warning"
            message: "Legacy yazelix.nix configuration detected"
            details: ($yazelix_legacy | path expand)
            fix_available: false
        })
    } else if ($yazelix_default | path expand | path exists) {
        $results = ($results | append {
            status: "info"
            message: "Using default configuration (yazelix_default.toml)"
            details: "Consider copying to yazelix.toml for customization"
            fix_available: true
        })
    } else {
        $results = ($results | append {
            status: "error"
            message: "No configuration file found"
            details: "Neither yazelix.toml nor yazelix_default.toml exists"
            fix_available: false
        })
    }
    
    $results
}

# Check shell integration
export def check_shell_integration [] {
    let yzx_available = try {
        (which yzx | is-not-empty)
    } catch {
        false
    }
    
    if $yzx_available {
        {
            status: "ok"
            message: "yzx commands available"
            details: "Shell integration working properly"
            fix_available: false
        }
    } else {
        {
            status: "warning"
            message: "yzx commands not found in PATH"
            details: "Shell integration may not be properly configured"
            fix_available: false
        }
    }
}

# Check log files
export def check_log_files [] {
    let logs_dir = "~/.config/yazelix/logs"
    let logs_path = ($logs_dir | path expand)

    if not ($logs_path | path exists) {
        return {
            status: "info"
            message: "No logs directory found"
            details: "Logs will be created when needed"
            fix_available: false
        }
    }

    let large_logs = try {
        (ls $logs_path | where type == file and size > 10MB)
    } catch {
        []
    }

    if not ($large_logs | is-empty) {
        let large_files = ($large_logs | get name | path basename | str join ", ")
        {
            status: "warning"
            message: $"Large log files found: ($large_files)"
            details: "Consider cleaning up logs to improve performance"
            fix_available: true
        }
    } else {
        {
            status: "ok"
            message: "Log files are reasonable size"
            details: $"Logs directory: ($logs_path)"
            fix_available: false
        }
    }
}

# Clean large log files
export def fix_large_logs [] {
    let logs_dir = "~/.config/yazelix/logs"
    let logs_path = ($logs_dir | path expand)
    
    if not ($logs_path | path exists) {
        return true
    }
    
    try {
        let large_logs = (ls $logs_path | where type == file and size > 10MB)
        
        for $log in $large_logs {
            rm $log.name
            print $"✅ Removed large log file: ($log.name | path basename)"
        }
        
        return true
    } catch {
        print "❌ Failed to clean log files"
        return false
    }
}

# Create yazelix.toml from default
export def fix_create_config [] {
    let yazelix_config = "~/.config/yazelix/yazelix.toml"
    let yazelix_default = "~/.config/yazelix/yazelix_default.toml"

    try {
        cp ($yazelix_default | path expand) ($yazelix_config | path expand)
        print $"✅ Created yazelix.toml from template"
        return true
    } catch {
        print "❌ Failed to create yazelix.toml"
        return false
    }
}


# Main doctor function
export def run_doctor_checks [verbose: bool = false, fix: bool = false] {
    print "🔍 Running Yazelix Health Checks...\n"
    
    # Collect all checks
    mut all_results = []

    # Environment variables
    $all_results = ($all_results | append (check_environment_variables))

    # Configuration
    $all_results = ($all_results | append (check_configuration))

    # Shell integration
    $all_results = ($all_results | append (check_shell_integration))

    # Log files
    $all_results = ($all_results | append (check_log_files))

    # Display results
    let errors = ($all_results | where status == "error")
    let warnings = ($all_results | where status == "warning") 
    let infos = ($all_results | where status == "info")
    let oks = ($all_results | where status == "ok")
    
    # Show results
    for $result in $all_results {
        match $result.status {
            "ok" => { print $"✅ ($result.message)" }
            "info" => { print $"ℹ️  ($result.message)" }
            "warning" => { print $"⚠️  ($result.message)" }
            "error" => { print $"❌ ($result.message)" }
        }
        
        if $verbose and ($result.details | is-not-empty) {
            print $"   ($result.details)"
        }
    }
    
    print ""
    
    # Summary
    if not ($errors | is-empty) {
        print $"❌ Found ($errors | length) errors"
    }
    
    if not ($warnings | is-empty) {
        print $"⚠️  Found ($warnings | length) warnings"
    }
    
    if ($errors | is-empty) and ($warnings | is-empty) {
        print "🎉 All checks passed! Yazelix is healthy."
        return
    }
    
    # Auto-fix if requested
    if $fix {
        print "\n🔧 Attempting to auto-fix issues...\n"
        
        # Fix large logs
        let log_issues = ($all_results | where status == "warning" and message =~ "log")
        if not ($log_issues | is-empty) {
            fix_large_logs
        }
        
        # Fix missing config
        let config_issues = ($all_results | where status == "info" and message =~ "default")
        if not ($config_issues | is-empty) {
            fix_create_config
        }

        print "\n✅ Auto-fix completed. Run 'yzx doctor' again to verify."
    } else if (($all_results | where fix_available == true) | is-not-empty) {
        print "\n💡 Some issues can be auto-fixed. Run 'yzx doctor --fix' to resolve them."
    }
}
