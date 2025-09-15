#!/usr/bin/env nu

# Enhanced Nix Build for Emacs (Nushell version)
# Builds with verbose output and automatic progress monitoring

def main [
    ...args  # Additional arguments to pass to nb
] {
    print "🚀 Starting Nix build with Emacs progress monitoring..."
    print "📊 Build output will show detailed Emacs compilation progress"
    print "⏱️  Expected total time: 30-60 minutes for full Emacs build"
    print ""

    # Check if emacs-build-monitor is available
    let monitor_available = (which emacs-build-monitor | length) > 0

    if $monitor_available {
        print "🔍 Using emacs-build-monitor for progress tracking"
        print "───────────────────────────────────────────────────────"

        try {
            # Run nb with verbose output and pipe through the monitor
            nb --verbose --show-trace ...$args | emacs-build-monitor --follow
            print ""
            print "✅ Build completed successfully!"
            print "💡 Run 'ns' to switch to the new configuration"
        } catch { |e|
            print ""
            print "❌ Build failed:"
            print $e.msg
            print "💡 Check the error messages above for details"
            exit 1
        }
    } else {
        print "⚠️  emacs-build-monitor not found, using standard verbose build"
        print "───────────────────────────────────────────────────────"

        try {
            # Fallback to regular verbose build
            nb --verbose --show-trace ...$args
            print ""
            print "✅ Build completed successfully!"
            print "💡 Run 'ns' to switch to the new configuration"
        } catch { |e|
            print ""
            print "❌ Build failed:"
            print $e.msg
            print "💡 Check the error messages above for details"
            exit 1
        }
    }
}