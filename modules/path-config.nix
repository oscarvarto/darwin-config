{
  config,
  pkgs,
  lib,
  user,
  ...
}: let
  # ============================================================================
  # CENTRALIZED PATH CONFIGURATION
  # ============================================================================
  # This is your single source of truth for PATH management across all shells
  # Paths are listed in priority order (first = highest priority)
  # Add your custom paths at the top of the list to override everything else
  pathEntries = [
    # -------------------------------------------------------------------------
    # HIGH PRIORITY - YOUR CUSTOM PATHS (add your overrides here)
    # -------------------------------------------------------------------------
    # Examples:
    # "/path/to/your/priority/tools/bin"
    # "$HOME/my-custom-tools/bin"
    # "/usr/local/my-app/bin"

    # -------------------------------------------------------------------------
    # DEVELOPMENT TOOLS (highest priority after custom)
    # -------------------------------------------------------------------------
    "$HOME/.volta/bin" # Node.js version manager
    "$HOME/Library/Application Support/Coursier/bin" # Scala/JVM tools
    "$HOME/bin" # User binaries
    "$HOME/.emacs.d/bin" # Doom Emacs tools
    "$HOME/.cargo/bin" # Rust tools
    "$HOME/.local/bin" # User local binaries
    "$HOME/.local/share/bin" # User shared binaries
    "$HOME/.npm-packages/bin" # Global npm packages
    "$HOME/darwin-config/modules/elisp-formatter" # Emacs Lisp formatter

    # -------------------------------------------------------------------------
    # PACKAGE MANAGERS
    # -------------------------------------------------------------------------
    "$HOME/.nix-profile/bin" # Nix user profile
    "/nix/var/nix/profiles/default/bin" # Nix system profile
    "/etc/profiles/per-user/$USER/bin" # Nix-darwin user profile

    # -------------------------------------------------------------------------
    # HOMEBREW TOOLS
    # -------------------------------------------------------------------------
    "/opt/homebrew/bin" # Homebrew binaries
    "/opt/homebrew/sbin" # Homebrew system binaries
    "/opt/homebrew/opt/llvm/bin" # LLVM tools
    "/opt/homebrew/opt/mysql@8.4/bin" # MySQL tools
    "/opt/homebrew/opt/gnu-tar/libexec/gnubin" # GNU tar
    "/opt/homebrew/opt/trash-cli/bin" # Trash CLI

    # -------------------------------------------------------------------------
    # SYSTEM AND FRAMEWORK PATHS
    # -------------------------------------------------------------------------
    "/run/current-system/sw/bin" # NixOS system tools
    "/usr/local/share/dotnet" # .NET Core
    "$HOME/.dotnet/tools" # .NET user tools
    "$HOME/.swiftpm/bin"

    # -------------------------------------------------------------------------
    # STANDARD SYSTEM PATHS (lowest priority)
    # -------------------------------------------------------------------------
    "/usr/local/bin" # User-installed system tools
    "/usr/bin" # System binaries
    "/bin" # Essential system binaries
    "/usr/sbin" # System administration
    "/sbin" # System administration
  ];

  # Function to expand environment variables in paths
  expandPath = path:
    if lib.hasPrefix "$HOME" path
    then lib.replaceStrings ["$HOME"] ["/Users/${user}"] path
    else path;

  # Generate the PATH list with expanded variables
  expandedPaths = map expandPath pathEntries;

  # Generate zsh-compatible path array
  zshPaths = lib.concatStringsSep "\n        " (map (path: "\"${path}\"") pathEntries);

  # Generate nushell-compatible path list
  nushellPaths = lib.concatStringsSep "\n    " (map (path: "\"${expandPath path}\"") pathEntries);
in {
  # Export the path configuration for use in other modules
  _module.args.pathConfig = {
    inherit pathEntries expandedPaths;

    # Shell-specific configurations with mise override capability
    zsh = {
      pathSetup = ''
        # ============================================================================
        # CENTRALIZED PATH SETUP - CONTROLLED BY modules/path-config.nix
        # ============================================================================
        # This overrides mise, homebrew, and any other tool that tries to modify PATH

        declare -a desired_paths=(
        ${zshPaths}
        )

        # Build authoritative PATH - only include paths that exist
        new_path=""
        for path in "''${desired_paths[@]}"; do
          # Expand environment variables for zsh
          expanded_path=''${path//\$HOME/$HOME}
          if [[ -d "$expanded_path" ]]; then
            if [[ -z "$new_path" ]]; then
              new_path="$expanded_path"
            else
              new_path="$new_path:$expanded_path"
            fi
          fi
        done

        # Override any system or tool-set PATH with our authoritative version
        export PATH="$new_path"
      '';

      # This runs AFTER all integrations to enforce our PATH
      pathOverride = ''
        # ============================================================================
        # AUTHORITATIVE PATH OVERRIDE - RUNS AFTER ALL INTEGRATIONS
        # ============================================================================
        # This ensures our PATH takes precedence over mise, homebrew, etc.

        declare -a desired_paths=(
        ${zshPaths}
        )

        # Rebuild our desired PATH
        our_path=""
        for path in "''${desired_paths[@]}"; do
          expanded_path=''${path//\$HOME/$HOME}
          if [[ -d "$expanded_path" ]]; then
            if [[ -z "$our_path" ]]; then
              our_path="$expanded_path"
            else
              our_path="$our_path:$expanded_path"
            fi
          fi
        done

        # Force our PATH to take precedence
        export PATH="$our_path"

        # Optional: Preserve additional tool-added paths at lower priority
        # Uncomment if you want to keep some tool-added paths:
        # current_path_array=(''${PATH//:/ })
        # for path in "''${current_path_array[@]}"; do
        #   if [[ ":$our_path:" != *":$path:"* ]] && [[ -d "$path" ]]; then
        #     our_path="$our_path:$path"
        #   fi
        # done
        # export PATH="$our_path"
      '';
    };

    nushell = {
      pathSetup = ''
            # ============================================================================
            # CENTRALIZED PATH SETUP - CONTROLLED BY modules/path-config.nix
            # ============================================================================
            # This overrides mise, homebrew, and any other tool that tries to modify PATH

            let desired_paths = [
        ${nushellPaths}
            ]

            # Build authoritative PATH - only include paths that exist
            $env.PATH = ($desired_paths | where {|p| $p | path exists})
      '';

      # This runs AFTER all integrations to enforce our PATH
      pathOverride = ''
            # ============================================================================
            # AUTHORITATIVE PATH OVERRIDE - RUNS AFTER ALL INTEGRATIONS
            # ============================================================================
            # This ensures our PATH takes precedence over mise, homebrew, etc.

            let desired_paths = [
        ${nushellPaths}
            ]

            # Force our PATH to take precedence
            $env.PATH = ($desired_paths | where {|p| $p | path exists})

            # Optional: Preserve additional tool-added paths at lower priority
            # Uncomment if you want to keep some tool-added paths:
            # let current_paths = $env.PATH
            # let our_paths = ($desired_paths | where {|p| $p | path exists})
            # let additional_paths = ($current_paths | where {|p| $p not-in $our_paths})
            # $env.PATH = ($our_paths | append $additional_paths)
      '';
    };

    fish = {
      pathSetup = ''
        # ============================================================================
        # CENTRALIZED PATH SETUP - CONTROLLED BY modules/path-config.nix
        # ============================================================================
        # This overrides mise, homebrew, and any other tool that tries to modify PATH

        set -l desired_paths \
            ${lib.concatStringsSep " \\\n            " (map (path: "\"${path}\"") pathEntries)}

        # Build authoritative PATH - only include paths that exist
        set -g fish_user_paths
        for path in $desired_paths
            # Expand environment variables for fish
            set expanded_path (string replace '$HOME' $HOME $path)
            if test -d $expanded_path
                set -ga fish_user_paths $expanded_path
            end
        end

        # Override any system or tool-set PATH with our authoritative version
        set -gx PATH $fish_user_paths
      '';

      # This runs AFTER all integrations (mise, etc.) to enforce our PATH
      pathOverride = ''
        # ============================================================================
        # AUTHORITATIVE PATH OVERRIDE - RUNS AFTER ALL INTEGRATIONS
        # ============================================================================
        # This ensures our PATH takes precedence over mise, homebrew, etc.

        # Rebuild our desired PATH
        set -l desired_paths \
            ${lib.concatStringsSep " \\\n            " (map (path: "\"${path}\"") pathEntries)}

        set -l our_path
        for path in $desired_paths
            set expanded_path (string replace '$HOME' $HOME $path)
            if test -d $expanded_path
                set -a our_path $expanded_path
            end
        end

        # Force our PATH to take precedence
        set -gx PATH $our_path

        # Optional: Add any additional paths that other tools added (but at lower priority)
        # Uncomment the next few lines if you want to preserve some tool-added paths:
        # for path in (echo $PATH | tr ':' '\n')
        #     if not contains $path $our_path
        #         set -a our_path $path
        #     end
        # end
        # set -gx PATH $our_path
      '';
    };
  };
}
