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

$env.AWS_REGION = "us-east-1"
$env.AWS_DEFAULT_REGION = "us-east-1"

# Starship configuration path
$env.STARSHIP_CONFIG = ($env.HOME | path join ".config" "starship.toml")

# Set up clean PATH with deduplication - define our desired order
# This ensures consistent PATH across shells and removes duplicates
let desired_paths = [
    ($env.HOME | path join ".volta" "bin")
    ($env.HOME | path join "Library" "Application Support" "Coursier" "bin") 
    ($env.HOME | path join "bin")
    ($env.HOME | path join ".emacs.d" "bin")
    ($env.HOME | path join ".cargo" "bin")
    ($env.HOME | path join ".local" "bin")
    ($env.HOME | path join ".local" "share" "bin")
    ($env.HOME | path join ".npm-packages" "bin")
    ($env.HOME | path join "darwin-config" "modules" "elisp-formatter")
    ($env.HOME | path join ".nix-profile" "bin")
    "/nix/var/nix/profiles/default/bin"
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "/Library/TeX/texbin"
    "/run/current-system/sw/bin"
    "/opt/homebrew/opt/gnu-tar/libexec/gnubin"
    "/opt/homebrew/opt/mysql@8.4/bin"
    "/usr/local/share/dotnet"
    ($env.HOME | path join ".dotnet" "tools")
    "/opt/homebrew/opt/llvm/bin"
    "/usr/local/bin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
]

# Build clean PATH by filtering for existing directories and removing duplicates
$env.PATH = ($desired_paths | where {|p| $p | path exists} | uniq)

# Set environment variables that apps might need
$env.DOTNET_ROOT = "/usr/local/share/dotnet"
$env.CARGO_HOME = ($env.HOME | path join ".cargo")
$env.EMACSDIR = "~/.emacs.d"
$env.DOOMDIR  = "~/.doom.d"
$env.DOOMLOCALDIR = "~/.emacs.d/.local"

# Set Xcode developer directory to beta version
$env.DEVELOPER_DIR = "/Applications/Xcode-beta.app/Contents/Developer"
