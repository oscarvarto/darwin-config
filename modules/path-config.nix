{
  config,
  pkgs,
  lib,
  user,
  darwinConfigPath,
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
    # "$HOME/apache-maven-4.0.0-rc-5/bin"
    "$HOME/.emacs.d/.cache/lsp/eclipse.jdt.ls/bin"
    "$HOME/.opencode/bin"
    "/opt/homebrew/opt/grep/libexec/gnubin"
    "/opt/homebrew/opt/postgresql@15/bin"
    "/Users/oscarvarto/Library/Application Support/JetBrains/Toolbox/scripts"

    # -------------------------------------------------------------------------
    # DEVELOPMENT TOOLS (highest priority after custom)
    # -------------------------------------------------------------------------
    "$HOME/.local/share/mise/shims" # mise shims (preferred)
    "$HOME/.volta/bin" # Node.js version manager
    "$HOME/bin" # User binaries
    "$HOME/.emacs.d/bin" # Doom Emacs tools
    "$HOME/.cargo/bin" # Rust tools
    "$HOME/.local/bin" # User local binaries
    "$HOME/.local/share/bin" # User shared binaries
    "$HOME/.npm-packages/bin" # Global npm packages
    "${darwinConfigPath}/modules/elisp-formatter" # Emacs Lisp formatter

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
    "/opt/homebrew/opt/lld/bin"
    "/opt/homebrew/opt/mysql@8.4/bin" # MySQL tools
    "/opt/homebrew/opt/gnu-tar/libexec/gnubin" # GNU tar
    "/opt/homebrew/opt/trash-cli/bin" # Trash CLI

    # -------------------------------------------------------------------------
    # SYSTEM AND FRAMEWORK PATHS
    # -------------------------------------------------------------------------
    "/Library/TeX/Distributions/.DefaultTeX/Contents/Programs/texbin" # LaTeX tools (MacTeX/TeXDist)
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

  # Generate zsh-compatible path array (leave $HOME/$USER for runtime expansion)
  zshPaths = lib.concatStringsSep "\n        " (map (path: "\"${path}\"") pathEntries);

  # Bash uses the same quoting requirements as zsh for PATH bootstrapping
  bashPaths = zshPaths;

  # Generate nushell-compatible path list
  nushellPaths = lib.concatStringsSep "\n    " (map (path: "\"${expandPath path}\"") pathEntries);

  # Generate xonsh-compatible path list
  xonshPaths = lib.concatStringsSep ",\n          " (map (path: "\"${expandPath path}\"") pathEntries);
in {
  # Export the path configuration for use in other modules
  _module.args.pathConfig = {
    inherit pathEntries expandedPaths;

    # Shell-specific configurations with mise override capability
    bash = {
      pathSetup = ''
        # ============================================================================
        # CENTRALIZED PATH SETUP - CONTROLLED BY modules/path-config.nix
        # ============================================================================
        # This overrides mise, homebrew, and any other tool that tries to modify PATH

        # Seed PATH from macOS path_helper (adds entries from /etc/paths and /etc/paths.d)
        if [ -x /usr/libexec/path_helper ]; then
          eval "$(/usr/libexec/path_helper -s)"
        fi

        desired_paths=(
        ${bashPaths}
        )

        # Build authoritative PATH - only include paths that exist
        new_path=""
        for path in "''${desired_paths[@]}"; do
          expanded_path="''${path//\$HOME/$HOME}"
          expanded_path="''${expanded_path//\$USER/$USER}"
          if [ -d "$expanded_path" ] || [ -L "$expanded_path" ]; then
            if [ -z "$new_path" ]; then
              new_path="$expanded_path"
            else
              new_path="$new_path:$expanded_path"
            fi
          fi
        done

        # Override any system or tool-set PATH with our authoritative version
        if [ -n "$new_path" ]; then
          export PATH="$new_path"
        fi
      '';

      # This runs AFTER all integrations to enforce our PATH
      pathOverride = ''
        # ============================================================================
        # AUTHORITATIVE PATH OVERRIDE - RUNS AFTER ALL INTEGRATIONS
        # ============================================================================
        # This ensures our PATH takes precedence over mise, homebrew, etc.

        # Snapshot current PATH after all integrations
        original_path="$PATH"

        # Incorporate macOS path_helper (e.g., TeX from /etc/paths.d/TeX)
        if [ -x /usr/libexec/path_helper ]; then
          eval "$(/usr/libexec/path_helper -s)"
          PATH="$PATH:$original_path"
        fi

        desired_paths=(
        ${bashPaths}
        )

        # Rebuild our desired PATH
        our_path=""
        for path in "''${desired_paths[@]}"; do
          expanded_path="''${path//\$HOME/$HOME}"
          expanded_path="''${expanded_path//\$USER/$USER}"
          if [ -d "$expanded_path" ] || [ -L "$expanded_path" ]; then
            if [ -z "$our_path" ]; then
              our_path="$expanded_path"
            else
              our_path="$our_path:$expanded_path"
            fi
          fi
        done

        # Start with our desired list (which includes mise shims at top)
        final_path="$our_path"

        # Preserve additional tool-added paths (after our desired list)
        IFS=':' read -r -a original_path_array <<< "$original_path"
        for p in "''${original_path_array[@]}"; do
          if [ -n "$p" ] && [ -e "$p" ]; then
            case ":$final_path:" in
              *:"$p":*) ;;
              *)
                if [ -z "$final_path" ]; then
                  final_path="$p"
                else
                  final_path="$final_path:$p"
                fi
                ;;
            esac
          fi
        done

        # Force final PATH to our computed value
        if [ -n "$final_path" ]; then
          export PATH="$final_path"
        fi
      '';
    };

    zsh = {
      pathSetup = ''
        # ============================================================================
        # CENTRALIZED PATH SETUP - CONTROLLED BY modules/path-config.nix
        # ============================================================================
        # This overrides mise, homebrew, and any other tool that tries to modify PATH

        # Seed PATH from macOS path_helper (adds entries from /etc/paths and /etc/paths.d)
        if [[ -x /usr/libexec/path_helper ]]; then
          eval "$(/usr/libexec/path_helper -s)"
        fi

        typeset -a desired_paths=(
        ${zshPaths}
        )

        # Build authoritative PATH - only include paths that exist
        new_path=""
        for path in "''${desired_paths[@]}"; do
          # Expand environment variables for zsh
          expanded_path=''${path//\$HOME/$HOME}
          expanded_path=''${expanded_path//\$USER/$USER}
          if [[ -d "$expanded_path" || -L "$expanded_path" ]]; then
            if [[ -z "$new_path" ]]; then
              new_path="$expanded_path"
            else
              new_path="$new_path:$expanded_path"
            fi
          fi
        done

        # Override any system or tool-set PATH with our authoritative version
        export PATH="$new_path"
        path=(''${(s.:.)PATH})
        rehash
      '';

      # This runs AFTER all integrations to enforce our PATH
      pathOverride = ''
        # ============================================================================
        # AUTHORITATIVE PATH OVERRIDE - RUNS AFTER ALL INTEGRATIONS
        # ============================================================================
        # This ensures our PATH takes precedence over mise, homebrew, etc.

        # Snapshot current PATH after all integrations
        original_path="$PATH"

        # Incorporate macOS path_helper (e.g., TeX from /etc/paths.d/TeX)
        if [[ -x /usr/libexec/path_helper ]]; then
          eval "$(/usr/libexec/path_helper -s)"
          # Merge original PATH back in so we don't lose tool-added entries
          PATH="$PATH:$original_path"
        fi

        typeset -a desired_paths=(
        ${zshPaths}
        )

        # Rebuild our desired PATH
        our_path=""
        for path in "''${desired_paths[@]}"; do
          expanded_path=''${path//\$HOME/$HOME}
          expanded_path=''${expanded_path//\$USER/$USER}
          if [[ -d "$expanded_path" || -L "$expanded_path" ]]; then
            if [[ -z "$our_path" ]]; then
              our_path="$expanded_path"
            else
              our_path="$our_path:$expanded_path"
            fi
          fi
        done

        # Start with our desired list (which includes mise shims at top)
        final_path="$our_path"

        # Preserve additional tool-added paths (after our desired list)
        original_path_array=(''${original_path//:/ })
        for p in "''${original_path_array[@]}"; do
          if [[ -n "$p" && -e "$p" ]]; then
            if [[ ":$final_path:" != *":$p:"* ]]; then
              final_path="$final_path:$p"
            fi
          fi
        done

        # Force final PATH to our computed value
        export PATH="$final_path"
        path=(''${(s.:.)PATH})
        rehash
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

            # Build authoritative PATH - keep our desired order but preserve existing paths
            let current_paths = ($env.PATH? | default [])
            let our_paths = ($desired_paths | where {|p| $p | path exists})
            let additional_paths = (
                $current_paths
                | where {|p| ($p | path exists) and ($p not-in $our_paths) }
            )
            $env.PATH = ($our_paths | append $additional_paths | uniq)
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

    xonsh = {
      pathEntries = expandedPaths;

      pathSetup = ''
        # ============================================================================
        # CENTRALIZED PATH SETUP - CONTROLLED BY modules/path-config.nix
        # ============================================================================
        # This overrides mise, homebrew, and any other tool that tries to modify PATH

        desired_paths = [
          ${xonshPaths}
        ]

        # Build authoritative PATH - only include paths that exist
        import os
        valid_paths = []
        for path in desired_paths:
            if os.path.exists(path):
                valid_paths.append(path)

        # Set the PATH environment variable
        $PATH = valid_paths
      '';

      pathOverride = ''
        # ============================================================================
        # AUTHORITATIVE PATH OVERRIDE - RUNS AFTER ALL INTEGRATIONS
        # ============================================================================
        # This ensures our PATH takes precedence over mise, homebrew, etc.

        desired_paths = [
          ${xonshPaths}
        ]

        # Force our PATH to take precedence
        import os
        valid_paths = []
        for path in desired_paths:
            if os.path.exists(path):
                valid_paths.append(path)

        $PATH = valid_paths
      '';
    };
  };
}
