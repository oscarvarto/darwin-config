{ pkgs, lib, config, ... }:

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
  home-manager.users.oscarvarto = {
    # Add terminfo to user packages - this makes it available without conflicts
    home.packages = [ ghosttyTerminfo ];
    
    # Simple shell fallback - only if terminfo fails
    programs.zsh.initContent = lib.mkAfter ''
      # Simple Ghostty terminal compatibility fallback
      if [[ "$TERM" == "xterm-ghostty" ]] && ! command -v infocmp >/dev/null 2>&1; then
        export TERM="xterm-256color"
      elif [[ "$TERM" == "xterm-ghostty" ]] && ! infocmp xterm-ghostty >/dev/null 2>&1; then
        export TERM="xterm-256color"
      fi
    '';
  };
}
