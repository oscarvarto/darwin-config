def create_right_prompt [] {
    # create a right prompt in magenta with green separators and am/pm underlined
    let time_segment = ([
        (ansi reset)
        (ansi magenta)
        (date now | format date '%x %X %p') # try to respect user's locale
    ] | str join | str replace --regex --all "([/:])" $"(ansi green)${1}(ansi magenta)" |
        str replace --regex --all "([AP]M)" $"(ansi magenta_underline)${1}")

    let last_exit_code = if ($env.LAST_EXIT_CODE != 0) {([
        (ansi rb)
        ($env.LAST_EXIT_CODE)
    ] | str join)
    } else { "" }

    ([$last_exit_code, (char space), $time_segment] | str join)
}

# Use nushell functions to define your right and left prompt
$env.PROMPT_COMMAND = {|| create_left_prompt }
#$env.PROMPT_COMMAND_RIGHT = {|| create_right_prompt }
$env.PROMPT_COMMAND_RIGHT = ""

# The prompt indicators are environmental variables that represent
# the state of the prompt
$env.PROMPT_INDICATOR = {|| "> " }
$env.PROMPT_INDICATOR_VI_INSERT = {|| ": " }
$env.PROMPT_INDICATOR_VI_NORMAL = {|| "> " }
#$env.PROMPT_MULTILINE_INDICATOR = {|| "::: " }
$env.PROMPT_MULTILINE_INDICATOR = ""

# If you want previously entered commands to have a different prompt from the usual one,
# you can uncomment one or more of the following lines.
# This can be useful if you have a 2-line prompt and it's taking up a lot of space
# because every command entered takes up 2 lines instead of 1. You can then uncomment
# the line below so that previously entered commands show with a single `\U1F680`.
# $env.TRANSIENT_PROMPT_COMMAND = {|| "\U1F680 " }
# $env.TRANSIENT_PROMPT_INDICATOR = {|| "" }
# $env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT = {|| "" }
# $env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL = {|| "" }
# $env.TRANSIENT_PROMPT_MULTILINE_INDICATOR = {|| "" }
# $env.TRANSIENT_PROMPT_COMMAND_RIGHT = {|| "" }

# Specifies how environment variables are:
# - converted from a string to a value on Nushell startup (from_string)
# - converted from a value back to a string when running external commands (to_string)
# Note: The conversions happen *after* config.nu is loaded
$env.ENV_CONVERSIONS = {
    "PATH": {
        from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
    }
    "Path": {
        from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
    }
}

# Directories to search for scripts when calling source or use
# The default for this is $nu.default-config-dir/scripts
$env.NU_LIB_DIRS = [
    ($nu.default-config-dir | path join 'scripts') # add <nushell-config-dir>/scripts
]

# Directories to search for plugin binaries when calling register
# The default for this is $nu.default-config-dir/plugins
$env.NU_PLUGIN_DIRS = [
    ($nu.default-config-dir | path join 'plugins') # add <nushell-config-dir>/plugins
]

# To add entries to PATH (on Windows you might use Path), you can use the following pattern:
# $env.PATH = ($env.PATH | split row (char esep) | prepend '/some/path')
use std/util "path add"

path add "/opt/homebrew/bin"
path add "/opt/homebrew/opt/llvm/bin"
path add "/opt/homebrew/opt/mysql@8.4/bin"
path add "/opt/homebrew/opt/gnu-tar/libexec/gnubin"
path add "/run/current-system/sw/bin"

$env.DOTNET_ROOT = "/usr/local/share/dotnet"
path add $env.DOTNET_ROOT
path add "~/.dotnet/tools"
path add "~/.local/share/bin"
path add "~/.local/bin"
$env.CARGO_HOME = ($env.HOME | path join ".cargo")
path add ($env.CARGO_HOME | path join "bin")
path add "~/nixos-config/modules/shared/elisp-formatter"

$env.EMACSDIR = "~/.emacs.d"
$env.DOOMDIR  = "~/.doom.d"
$env.DOOMLOCALDIR = "~/.emacs.d/.local"
path add ($env.EMACSDIR | path join "bin")
path add "~/Library/Application Support/Coursier/bin"
path add "~/.volta/bin"
path add "~/Library/Application Support/JetBrains/Toolbox/scripts"
path add "~/.nix-profile/bin"
path add "/opt/homebrew/opt/trash-cli/bin"
path add "/usr/local/bin"
path add "/Library/TeX/texbin"
