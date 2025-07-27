{ ... }:

{
  programs.fish = {
    enable = true;
    generateCompletions = false;
    shellInit = ''
      # Nix daemon initialization
      if test -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
        set -gx NIX_SSL_CERT_FILE /nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt
        set -gx NIX_PROFILES "/nix/var/nix/profiles/default $HOME/.nix-profile"
        set -gx NIX_PATH "/nix/var/nix/profiles/per-user/root/channels"
        fish_add_path /nix/var/nix/profiles/default/bin
      end
    '';

    interactiveShellInit = ''

      # Unset the default fish greeting text which messes up Zellij
      set fish_greeting
      set -gx fish_color_autosuggestion brmagenta

      # Environment variables
      set -gx LC_ALL "en_US.UTF-8"
      set -gx ALTERNATE_EDITOR ""
      set -gx EDITOR nvim
      set -gx VISUAL nvim

      # Check if we're in an interactive shell
      # if status is-interactive
      #     # At this point, specify the Zellij config dir, so we can launch it manually if we want to
      #     export ZELLIJ_CONFIG_DIR=$HOME/.config/zellij

      #     # Check if our Terminal emulator is Ghostty, we're not already in zellij,
      #     # and fish is the login shell (not invoked from another shell)
      #     if [ "$TERM" = "xterm-ghostty" ] && not set -q ZELLIJ && [ "$SHLVL" = "1" ]
      #         # Launch zellij with fish as the default shell
      #         exec zellij
      #     end
      # end

      # PATH configuration
      fish_add_path /usr/local/bin
      fish_add_path /opt/homebrew/bin
      fish_add_path /opt/homebrew/opt/llvm/bin
      fish_add_path /opt/homebrew/opt/mysql@8.4/bin
      fish_add_path /opt/homebrew/opt/gnu-tar/libexec/gnubin
      fish_add_path /run/current-system/sw/bin

      # Environment variables for compilation
      set -gx LDFLAGS "-L/opt/homebrew/opt/llvm/lib"
      set -gx CPPFLAGS "-I/opt/homebrew/opt/llvm/include"

      # .NET configuration
      set -gx DOTNET_ROOT /usr/local/share/dotnet
      fish_add_path $DOTNET_ROOT
      fish_add_path $HOME/.dotnet/tools
      
      # Define variables for directories
      set -gx EMACSDIR $HOME/.emacs.d
      set -gx DOOMDIR $HOME/.doom.d
      set -gx DOOMLOCALDIR $HOME/.emacs.d/.local

      # PATH configuration
      fish_add_path $HOME/.pnpm-packages/bin
      fish_add_path $HOME/.pnpm-packages
      fish_add_path $HOME/.npm-packages/bin
      fish_add_path $HOME/bin
      fish_add_path $HOME/.local/share/bin
      fish_add_path $HOME/.local/bin
      fish_add_path $HOME/.cargo/bin
      fish_add_path $HOME/nixos-config/modules/shared/elisp-formatter
      fish_add_path $EMACSDIR/bin
      fish_add_path "$HOME/Library/Application Support/Coursier/bin"
      fish_add_path "$HOME/.volta/bin"
      fish_add_path $HOME/.dotnet/tools
      fish_add_path /opt/homebrew/opt/trash-cli/bin
      fish_add_path "$HOME/.nix-profile/bin"
      fish_add_path "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"
      fish_add_path "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/"
      '';

    functions = {
      ppath = {
        body = ''
          for p in $PATH
            echo $p
          end
        '';
      };

      # Nix shell shortcut
      shell = {
        body = ''nix-shell '<nixpkgs>' -A "$argv[1]"'';
        description = "Enter nix-shell for package";
      };
    };

    shellAbbrs = {
      # 1Password plugin aliases (fallback to regular commands if no session)
      # aws = "if set -q OP_SESSION_my; op plugin run -- aws; else; command aws; end";
      # cachix = "if set -q OP_SESSION_my; op plugin run -- cachix; else; command cachix; end";
      # gh = "op plugin run -- gh";
      # glab = "op plugin run -- glab";
      
      # 1Password session management
      op-auth = "set -e OP_SESSION_my; rm -f ~/.config/op/session*; op signin";
      op-status = "if set -q OP_SESSION_my; printf '\u2705 1Password session active\n'; else; printf '\u274c No 1Password session\n'; end";

      # Utility aliases
      search = "rg -p --glob '!node_modules/*'";
      diff = "difft";

      # Terminal and editor shortcuts
      tg = "$EDITOR $HOME/.config/ghostty/config";
      tgg = "$EDITOR $HOME/.config/ghostty/overrides.conf";
      edd = "emacs --daemon=doom";
      pke = "pkill -9 Emacs";
      nf = "nvim ~/nixos-config/modules/darwin/fish-config.nix";
      gd = "ghostty +show-config --default --docs";

      # Git shortcuts
      gp = "git fetch --all -p; git pull; git submodule update --recursive";

      # Doom Emacs shortcuts
      ds = "doom sync --aot --gc -j (nproc)";
      dup = "doom sync -u --aot --gc -j (nproc)";

      # Nix shortcuts
      nb = "pushd $HOME/nixos-config >/dev/null; nix run .#build; popd >/dev/null";
      ns = "pushd $HOME/nixos-config >/dev/null; nix run .#build-switch; popd >/dev/null";
    };
  };
}
