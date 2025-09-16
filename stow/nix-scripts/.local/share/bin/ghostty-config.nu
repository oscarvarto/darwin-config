#!/usr/bin/env nu
# Ghostty configuration helper for quick changes

# Colors
const RED = "\u{001b}[0;31m"
const GREEN = "\u{001b}[0;32m"
const YELLOW = "\u{001b}[1;33m"
const BLUE = "\u{001b}[0;34m"
const NC = "\u{001b}[0m"

const OVERRIDES_FILE = "~/.config/ghostty/overrides.conf"

def show_help [] {
  print $"($BLUE)👻 Ghostty Configuration Helper($NC)"
  print ""
  print "Usage: ghostty-config [COMMAND] [OPTIONS]"
  print ""
  print "Commands:"
  print "  font <font-name> [<size>]   Set font (and optional size)"
  print "  theme <theme-name>         Set theme"
  print "  shell <shell-name>         Set shell for new terminals"
  print "  opacity <value>          Set background opacity (0.0-1.0)"
  print "  reset                   Reset overrides to defaults"
  print "  list                    Show available options"
  print "  current                 Show current override settings"
  print "  edit                    Open overrides file in editor"
  print ""
  print "Font Examples:"
  print "  ghostty-config font 'MonoLisaVariable Nerd Font' 14"
  print "  ghostty-config font 'PragmataPro Mono Liga' 18"
  print "  ghostty-config font 'JetBrains Mono'"
  print ""
  print "Theme Examples:"
  print "  ghostty-config theme Dracula"
  print "  ghostty-config theme BlulocoLight"
  print "  ghostty-config theme nord"
  print ""
  print "Shell Examples:"
  print "  ghostty-config shell fish"
  print "  ghostty-config shell zsh"
  print "  ghostty-config shell bash"
  print "  ghostty-config shell nushell"
  print "  ghostty-config shell pwsh"
  print ""
  print "Other Examples:"
  print "  ghostty-config opacity 0.9"
  print "  ghostty-config reset"
}

def ensure_config_dir [] {
  let dir = ($OVERRIDES_FILE | path dirname | path expand)
  mkdir $dir
  if not ($OVERRIDES_FILE | path expand | path exists) {
    touch ($OVERRIDES_FILE | path expand)
  }
}

def update_setting [key: string, value: string] {
  ensure_config_dir
  
  let file_path = ($OVERRIDES_FILE | path expand)
  
  # Remove existing setting if it exists
  let content = (open $file_path | lines | where { |line| not ($line | str contains $"($key) =") } | str join "\n")
  
  # Add new setting
  let new_content = $"($content)\n($key) = ($value)"
  $new_content | save -f $file_path
  
  print $"($GREEN)✅ Updated ($key) = ($value)($NC)"
}

def get_shell_path [shell_name: string] {
  let user_home = $env.HOME
  match $shell_name {
    "fish" => $"($user_home)/.nix-profile/bin/fish -i"
    "zsh" => "/bin/zsh -i"
    "bash" => "/bin/bash -i"
    "nushell" | "nu" => $"($user_home)/.nix-profile/bin/nu -i"
    "pwsh" | "powershell" => "/opt/homebrew/bin/pwsh -i"
    _ => ""
  }
}

def set_shell [shell_name: string] {
  let shell_path = (get_shell_path $shell_name)
  
  if ($shell_path | is-empty) {
    print $"($RED)❌ Unknown shell: ($shell_name)($NC)"
    print $"($YELLOW)Available shells: fish, zsh, bash, nushell, pwsh($NC)"
    return
  }
  
  # Check if shell exists
  let shell_binary = ($shell_path | split row " " | get 0)
  if not ($shell_binary | path exists) {
    print $"($RED)❌ Shell not found: ($shell_binary)($NC)"
    print $"($YELLOW)Make sure ($shell_name) is installed($NC)"
    return
  }
  
  # Update both command and initial-command
  update_setting "command" $shell_path
  update_setting "initial-command" $shell_path
  
  print $"($GREEN)🐚 Shell set to ($shell_name)($NC)"
}

def remove_setting [key: string] {
  let file_path = ($OVERRIDES_FILE | path expand)
  if ($file_path | path exists) {
    let content = (open $file_path | lines | where { |line| not ($line | str contains $"($key) =") } | str join "\n")
    $content | save -f $file_path
    print $"($GREEN)✅ Removed ($key) override($NC)"
  }
}

def restart_ghostty [] {
  print $"($YELLOW)🔄 Restarting Ghostty to apply changes...($NC)"
  # Kill existing Ghostty processes
  do { ^pkill -f Ghostty } | ignore
  sleep 1sec
  # Start Ghostty in background
  do { ^open -a Ghostty } | ignore
  print $"($GREEN)✅ Ghostty restarted($NC)"
}

def main [
  command: string = "help"
  ...args: string
] {
  match $command {
    "font" => {
      if ($args | length) == 0 {
        print $"($RED)❌ Font name required($NC)"
        show_help
        exit 1
      }
      
      ensure_config_dir
      let file_path = ($OVERRIDES_FILE | path expand)
      
      # Remove existing font-family lines
      let content = (open $file_path | lines | where { |line| not ($line | str contains "font-family =") } | str join "\n")
      
      # Add reset line first (empty quoted string as per Ghostty docs)
      let reset_content = $"($content)\nfont-family = \"\""
      $reset_content | save -f $file_path
      print $"($GREEN)✅ Added font-family reset($NC)"
      
      # Then add new font setting
      let font_name = ($args | get 0)
      let new_content = $"($reset_content)\nfont-family = \"($font_name)\""
      $new_content | save -f $file_path
      print $"($GREEN)✅ Updated font-family = ($font_name)($NC)"
      
      if ($args | length) > 1 {
        let size = ($args | get 1)
        update_setting "font-size" $size
      }
      restart_ghostty
    }
    "theme" => {
      if ($args | length) == 0 {
        print $"($RED)❌ Theme name required($NC)"
        show_help
        exit 1
      }
      let theme = ($args | get 0)
      update_setting "theme" $theme
      restart_ghostty
    }
    "opacity" => {
      if ($args | length) == 0 {
        print $"($RED)❌ Opacity value required($NC)"
        show_help
        exit 1
      }
      let opacity = ($args | get 0)
      update_setting "background-opacity" $opacity
      restart_ghostty
    }
    "shell" => {
      if ($args | length) == 0 {
        print $"($RED)❌ Shell name required($NC)"
        show_help
        exit 1
      }
      let shell = ($args | get 0)
      set_shell $shell
      restart_ghostty
    }
    "reset" => {
      print $"($YELLOW)🔄 Resetting overrides...($NC)"
      let file_path = ($OVERRIDES_FILE | path expand)
      "# Ghostty Runtime Overrides\n# Edit this file for quick changes without Nix rebuild\n# These settings override the base config\n\n" | save -f $file_path
      print $"($GREEN)✅ Overrides reset to defaults($NC)"
      restart_ghostty
    }
    "list" => {
      print $"($BLUE)📋 Available Options:($NC)"
      print ""
      print $"($YELLOW)Fonts:($NC)"
      print "  - MonoLisaVariable Nerd Font (commercial)"
      print "  - PragmataPro Mono Liga (commercial)"
      print "  - JetBrains Mono (open source fallback)"
      print "  - SF Mono (system)"
      print "  - Iosevka (open source)"
      print ""
      print $"($YELLOW)Themes:($NC)"
      print "  - Catppuccin Mocha (dark)"
      print "  - Catppuccin Latte (light)"
      print "  - Dracula"
      print "  - BlulocoLight"
      print "  - nord"
      print "  - github_light"
      print "  - tokyo-night"
      print "  - onedark"
      print "  - gruvbox"
      print ""
      print $"($YELLOW)Shells:($NC)"
      print "  - fish (default)"
      print "  - zsh"
      print "  - bash"
      print "  - nushell (nu)"
      print "  - pwsh (powershell)"
      print ""
      print $"($YELLOW)Font Sizes:($NC)"
      print "  - 12, 14, 16, 18, 20, 24"
      print ""
      print $"($YELLOW)Opacity:($NC)"
      print "  - 0.8 (very transparent)"
      print "  - 0.9 (semi-transparent)"
      print "  - 0.95 (slightly transparent)"
      print "  - 1.0 (opaque)"
    }
    "current" => {
      print $"($BLUE)📋 Current Override Settings:($NC)"
      let file_path = ($OVERRIDES_FILE | path expand)
      if ($file_path | path exists) and (($file_path | path type) == "file") {
        let content = (open $file_path | lines | where { |line| not ($line | str starts-with "#") and ($line | str trim | is-not-empty) })
        if ($content | length) > 0 {
          $content | each { |line| print $line } | ignore
        } else {
          print "No active overrides"
        }
      } else {
        print "No overrides file or empty"
      }
    }
    "edit" => {
      let editor = ($env.EDITOR? | default "nano")
      let file_path = ($OVERRIDES_FILE | path expand)
      ^$editor $file_path
      print $"($YELLOW)🔄 Restart Ghostty to apply manual changes($NC)"
    }
    "help" | "--help" | "-h" => {
      show_help
    }
    _ => {
      print $"($RED)❌ Unknown command: ($command)($NC)"
      show_help
      exit 1
    }
  }
}
