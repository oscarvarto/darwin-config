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
# Disabled to allow starship to handle the prompt
#$env.PROMPT_COMMAND = {|| create_left_prompt }
#$env.PROMPT_COMMAND_RIGHT = {|| create_right_prompt }
#$env.PROMPT_COMMAND_RIGHT = ""

# The prompt indicators are environmental variables that represent
# the state of the prompt
$env.PROMPT_INDICATOR = {|| "> " }
$env.PROMPT_INDICATOR_VI_INSERT = {|| ": " }
$env.PROMPT_INDICATOR_VI_NORMAL = {|| "> " }
$env.PROMPT_MULTILINE_INDICATOR = {|| "::: " }
# $env.PROMPT_MULTILINE_INDICATOR = ""

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

$env.AWS_REGION = "us-east-1"
$env.AWS_DEFAULT_REGION = "us-east-1"

# Starship configuration path
$env.STARSHIP_CONFIG = ($env.HOME | path join ".config" "starship.toml")

# Note: PATH is now managed by centralized path configuration in modules/path-config.nix
# The PATH will be set by the pathConfig.nushell.pathSetup configuration

# Set environment variables that apps might need
$env.DOTNET_ROOT = "/usr/local/share/dotnet"
$env.CARGO_HOME = ($env.HOME | path join ".cargo")
$env.EMACSDIR = "~/.emacs.d"
$env.BAT_THEME = "ansi"
$env.VCPKG_ROOT = ($env.HOME | path join "git-repos" "vcpkg")

# Ghostty terminfo location for proper terminal support in Emacs
$env.TERMINFO_DIRS = $"($env.HOME)/.terminfo:/usr/share/terminfo"

# Set Xcode developer directory to release version (forced rebuild)
$env.DEVELOPER_DIR = "/Applications/Xcode.app/Contents/Developer"

# Load theme from cache file set by catppuccin theme switcher
# Only set if not already defined (allows yazelix to override with dark theme)
if ($env.NUSHELL_THEME? | is-empty) {
    $env.NUSHELL_THEME = (try { open ~/.cache/nushell_theme | str trim } catch { "light" })
}

# Load Zellij theme config if available (now points to complete temp configs)
if (("~/.cache/zellij_theme_config" | path expand) | path exists) {
    let zellij_config_file = (try {
        open ~/.cache/zellij_theme_config |
        lines |
        find --regex 'export ZELLIJ_CONFIG_FILE=' |
        first |
        str replace 'export ZELLIJ_CONFIG_FILE=' '' |
        str trim --char '"'
    } catch { "" })

    # Only set the environment variable if the config file actually exists
    if ($zellij_config_file != "" and (($zellij_config_file | path expand) | path exists)) {
        $env.ZELLIJ_CONFIG_FILE = $zellij_config_file
    }
}

# JIRA API token is available on-demand via get-jira-api-token command
# To set it manually: $env.JIRA_API_TOKEN = (get-jira-api-token work)
# This avoids 1Password prompts on every shell startup
