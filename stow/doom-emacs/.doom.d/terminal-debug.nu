# Add this to ~/darwin-config/modules/nushell/config.nu
# 
# Debug function to check terminal and Emacs daemon status

def terminal-debug [] {
    print "🖥️  Terminal Debug Info:"
    print $"   TERM: {($env.TERM? | default 'Not set')}"
    print $"   TERMINFO_DIRS: {($env.TERMINFO_DIRS? | default 'Not set')}"
    
    # Test if xterm-ghostty terminfo is available
    let ghostty_terminfo = (do { ^infocmp xterm-ghostty } | complete)
    print $"   xterm-ghostty terminfo: {if ($ghostty_terminfo.exit_code == 0) { '✅ Available' } else { '❌ Not found' }}"
    
    # Test if we can connect to the Emacs daemon
    let socket_path = (doom-socket)
    if not ($socket_path | is-empty) {
let daemon_test = (do { ^/Users/oscarvarto/.nix-profile/bin/emacsclient -s $socket_path --eval "t" } | complete)
        print $"   Emacs daemon: {if ($daemon_test.exit_code == 0) { '✅ Connected' } else { '❌ Connection failed' }}"
    } else {
        print $"   Emacs daemon: ❌ Not running"
    }
    
    # Test current terminal Emacs connectivity
    print ""
    print "🧪 Testing terminal Emacs connection..."
let test_result = (do { ^/Users/oscarvarto/.nix-profile/bin/emacsclient -nw --eval "(message \"Terminal test successful\")" } | complete)
    if ($test_result.exit_code == 0) {
        print "✅ Terminal Emacs connection working!"
    } else {
        print "❌ Terminal Emacs connection failed"
        print $"   Error: {($test_result.stderr | str trim)}"
    }
}
