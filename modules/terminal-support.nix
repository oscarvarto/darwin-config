{ pkgs, lib, config, user, ... }:

let
  # Create the xterm-ghostty terminfo entry
  # Based on the Ghostty documentation and the fact that it's essentially xterm-compatible
  ghosttyTerminfo = pkgs.runCommand "ghostty-terminfo" {} ''
    mkdir -p $out/share/terminfo
    # Create a terminfo entry for xterm-ghostty that aliases to xterm-256color
    cat > xterm-ghostty.terminfo << 'EOF'
xterm-ghostty|Ghostty terminal emulator,
	use=xterm-256color,
	Tc,
	RGB,
	sitm=\E[3m,
	ritm=\E[23m,
	smso=\E[7m,
	rmso=\E[27m,
EOF
    ${pkgs.ncurses}/bin/tic -xe xterm-ghostty -o $out/share/terminfo xterm-ghostty.terminfo
  '';

in
{
  # Simple approach: just add the terminfo package to user environment
  # Darwin will handle the rest through its existing terminfo infrastructure
  home-manager.users.${user} = {
    # Add terminfo to user packages - this makes it available without conflicts
    home.packages = [ ghosttyTerminfo ];
    
    # Note: Terminal compatibility fallback has been moved to shell-config.nix
    # to avoid conflicts with multiple initContent definitions
  };
}
