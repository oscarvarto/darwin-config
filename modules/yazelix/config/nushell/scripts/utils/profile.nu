#!/usr/bin/env nu
# Yazelix Performance Profiler
# Profiles launch sequence and environment setup to identify bottlenecks

use logging.nu log_to_file
# Profile a single step with timing
def profile_step [name: string, code: closure] {
    let start = (date now)
    do $code
    let end = (date now)
    let duration = ($end - $start)

    # Convert nanoseconds to milliseconds
    let duration_ms = (($duration | into int) / 1000000)

    {
        step: $name
        duration_ms: $duration_ms
    }
}

# Profile environment setup components
export def profile_environment_setup [] {
    print "📊 Profiling environment setup components..."

    let yazelix_dir = "~/.config/yazelix" | path expand
    let log_file = "~/.local/share/yazelix/logs/profile.log" | path expand

    mut results = []

    # Profile initializers generation
    let init_result = (profile_step "Shell initializers generation" {
        nu $"($yazelix_dir)/nushell/scripts/setup/initializers.nu" $yazelix_dir true false "bash,nu"
        | complete
    })
    $results = ($results | append $init_result)

    # Profile config detection
    let config_result = (profile_step "Config hash computation" {
        let primary_config = $"($yazelix_dir)/yazelix.toml"
        let legacy_config = $"($yazelix_dir)/yazelix.nix"
        let config_file = if ($primary_config | path exists) {
            $primary_config
        } else {
            $legacy_config
        }
        if ($config_file | path exists) {
            open --raw $config_file | hash sha256
        }
    })
    $results = ($results | append $config_result)

    # Profile directory creation
    let dir_result = (profile_step "XDG directory setup" {
        let state_dir = "~/.local/share/yazelix/state" | path expand
        mkdir $state_dir
    })
    $results = ($results | append $dir_result)

    $results
}

# Profile cold launch from vanilla terminal (emulates desktop entry or fresh terminal launch)
export def profile_cold_launch [] {
    print "Cold launch profiling no longer uses devenv."
    print "Use normal launch profiling instead: yzx profile"
}

# Profile full launch sequence
export def profile_launch [] {
    print "🚀 Profiling Yazelix launch sequence...\n"

    mut all_results = []

    # Check if we're in a Yazelix shell already
    if ($env.IN_YAZELIX_SHELL? | is-not-empty) {
        print "⚠️  Already in Yazelix shell - measurements reflect warm start\n"
        print "💡 For cold start profiling, use: yzx profile --cold (from vanilla terminal)\n"
    }

    # Profile environment setup
    print "📋 Measuring environment setup components..."
    let env_results = (profile_environment_setup)
    $all_results = ($all_results | append $env_results)

    # Display results
    print "\n📊 Profile Results:\n"

    let total_ms = ($all_results | get duration_ms | math sum)

    # Format and display results
    let display_results = ($all_results | each {|result|
        let duration = ($result.duration_ms | math round --precision 2)
        {
            Step: $result.step
            "Duration (ms)": $duration
        }
    })

    print ($display_results | table)

    # Show total
    let total_rounded = ($total_ms | math round --precision 2)
    print $"\nTotal: ($total_rounded)ms"

    # Performance assessment
    print "\n💡 Performance Assessment:\n"

    if $total_ms < 200 {
        print "\n🚀 Excellent! Your setup is well-optimized."
    } else if $total_ms < 500 {
        print "\n✅ Good performance. Environment setup is efficient."
    } else if $total_ms < 2000 {
        print "\n⚠️  Moderate performance. Consider checking for slow operations."
    } else {
        print "\n❌ Slow performance detected. This may indicate:"
        print "   - First launch after config change (expected)"
        print "   - Slow disk I/O"
        print "   - Many extra packages in yazelix.toml"
    }
}
