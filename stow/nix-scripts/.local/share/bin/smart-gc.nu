#!/usr/bin/env nu
# Smart Nix Garbage Collection Script
# Preserves recent generations and avoids removing packages likely to be rebuilt

# Colors for output
const GREEN = "\u{001b}[1;32m"
const YELLOW = "\u{001b}[1;33m"
const RED = "\u{001b}[1;31m"
const BLUE = "\u{001b}[0;34m"
const NC = "\u{001b}[0m"

def show_help [] {
  print $"($BLUE)🧠 Smart Nix Garbage Collection($NC)"
  print ""
  print "Usage: smart-gc [OPTIONS] [COMMAND]"
  print ""
  print "Commands:"
  print "  status           Show current disk usage and generations"
  print "  dry-run          Show what would be cleaned (keeping last 3 generations)"
  print "  pin              Pin essential derivations to prevent removal"
  print "  clean [N]        Clean keeping last N generations (default: 3)"
  print "  aggressive       Aggressive cleanup (keep last 2 generations)"
  print "  conservative     Conservative cleanup (keep last 7 generations)"
  print ""
  print "Options:"
  print "  -h, --help       Show this help message"
  print "  -f, --force      Skip confirmation prompts"
  print "  -v, --verbose    Show detailed output"
  print "  --optimize       Run store optimization after cleanup (hard-link duplicate files, 25-35% savings)"
  print ""
  print "Examples:"
  print "  smart-gc status"
  print "  smart-gc dry-run"
  print "  smart-gc pin"
  print "  smart-gc clean 5"
  print "  smart-gc --force --optimize clean"
}

def show_status [] {
  print $"($BLUE)📊 Smart GC Status($NC)"
  
  let store_size = (do { ^du -sh /nix/store } | complete | get stdout | str trim | split row "\t" | get 0? | default "Unknown")
  print $"($YELLOW)├─ Store size:($NC) ($store_size)"
  
  print $"($YELLOW)├─ Home-manager generations:($NC)"
  let hm_generations = (^nix profile list --profile ~/.local/state/nix/profiles/home-manager 2>/dev/null | complete)
  if $hm_generations.exit_code == 0 {
    let gen_count = ($hm_generations.stdout | lines | length)
    print $"($YELLOW)│  ($gen_count) generations found($NC)"
  } else {
    print $"($YELLOW)│  No home-manager generations found($NC)"
  }
  
  print $"($YELLOW)├─ System profile generations:($NC)"
  let sys_generations = (^nix profile list --profile ~/.local/state/nix/profiles/profile 2>/dev/null | complete)
  if $sys_generations.exit_code == 0 {
    let gen_count = ($sys_generations.stdout | lines | length)
    print $"($YELLOW)│  ($gen_count) generations found($NC)"
  } else {
    print $"($YELLOW)│  No system profile generations found($NC)"
  }
  
  print $"($YELLOW)├─ GC roots:($NC)"
  let gc_roots = (do { ^find /nix/var/nix/gcroots -type l } | complete | get stdout | lines | length)
  print $"($YELLOW)│  ($gc_roots) GC roots found($NC)"
  
  print $"($YELLOW)└─ Garbage collection preview:($NC)"
  let gc_info = (do { ^nix store gc --dry-run } | complete)
  if $gc_info.exit_code == 0 {
    let gc_lines = ($gc_info.stdout | lines | length)
    print $"($YELLOW)   ($gc_lines) store paths would be deleted($NC)"
  } else {
    print $"($YELLOW)   Could not preview garbage collection($NC)"
  }
}

def perform_dry_run [keep_generations: int] {
  print $"($BLUE)💭 Smart GC Dry Run \(keeping last ($keep_generations) generations\)($NC)"

  print $"($YELLOW)📋 What would be cleaned:($NC)"

  # Check home-manager profile generations
  let hm_profile = "~/.local/state/nix/profiles/home-manager"
  let hm_result = (^nix profile history --profile $hm_profile 2>/dev/null | complete)
  if $hm_result.exit_code == 0 {
    let hm_generations = ($hm_result.stdout | lines | where {|line| $line | str contains "Version"} | length)
    if $hm_generations > $keep_generations {
      let to_remove = ($hm_generations - $keep_generations)
      print $"($YELLOW)├─ Home-manager: would remove ($to_remove) old generations \(keeping last ($keep_generations)\)($NC)"
    } else {
      print $"($YELLOW)├─ Home-manager: ($hm_generations) generations found, all within keep limit($NC)"
    }
  } else {
    print $"($YELLOW)├─ Home-manager: no profile found($NC)"
  }

  # Check system profile generations
  let sys_profile = "~/.local/state/nix/profiles/profile"
  let sys_result = (^nix profile history --profile $sys_profile 2>/dev/null | complete)
  if $sys_result.exit_code == 0 {
    let sys_generations = ($sys_result.stdout | lines | where {|line| $line | str contains "Version"} | length)
    if $sys_generations > $keep_generations {
      let to_remove = ($sys_generations - $keep_generations)
      print $"($YELLOW)├─ System profile: would remove ($to_remove) old generations \(keeping last ($keep_generations)\)($NC)"
    } else {
      print $"($YELLOW)├─ System profile: ($sys_generations) generations found, all within keep limit($NC)"
    }
  } else {
    print $"($YELLOW)├─ System profile: no profile found($NC)"
  }

  # Preview store garbage collection
  print $"($YELLOW)├─ Store cleanup preview:($NC)"
  let gc_result = (do { ^nix store gc --dry-run } | complete)
  if $gc_result.exit_code == 0 {
    let gc_lines = ($gc_result.stdout | lines | length)
    print $"($YELLOW)│  ($gc_lines) store paths would be deleted($NC)"
  } else {
    print $"($YELLOW)│  Could not preview store cleanup($NC)"
  }

  print $"($YELLOW)└─ No actual changes made - this was a dry run($NC)"
}

def pin_essentials [] {
  print $"($BLUE)📌 Pinning essential derivations to prevent removal($NC)"
  
  let essential_packages = [
    # "nixpkgs#git",
    # "nixpkgs#curl", 
    # "nixpkgs#starship",
    # "nixpkgs#helix",
    # "nixpkgs#yazi",
    # "nixpkgs#zoxide",
    # "nixpkgs#atuin",
    # "nixpkgs#jujutsu",
    # "nixpkgs#lazygit"
  ]
  
  # Create a gcroot for current system configuration if it exists
  let system_derivation = (do { ^nix-instantiate --add-root /nix/var/nix/gcroots/current-system '\u003cnixpkgs/nixos\u003e' -A system } | complete)
  if $system_derivation.exit_code == 0 {
    print $"($GREEN)✅ Pinned current system configuration($NC)"
  } else {
    print $"($YELLOW)ℹ️ Could not pin system configuration \(not a NixOS system\)($NC)"
  }
  
  print $"($YELLOW)📦 Pinning essential packages:($NC)"
  for pkg in $essential_packages {
    print $"($YELLOW)├─ Pinning ($pkg)...($NC)"
    let pin_result = (do { ^nix build --no-link --print-out-paths $pkg } | complete)
    if $pin_result.exit_code == 0 {
      print $"($GREEN)│  ✅ Successfully pinned ($pkg)($NC)"
    } else {
      print $"($RED)│  ❌ Failed to pin ($pkg)($NC)"
    }
  }
  
  print $"($GREEN)✅ Essential package pinning complete($NC)"
}

def perform_cleanup [keep_generations: int, force: bool, verbose: bool, optimize: bool] {
  print $"($BLUE)🧹 Starting smart garbage collection \(keeping last ($keep_generations) generations\)($NC)"

  if not $force {
    print $"($YELLOW)⚠️ This will remove old generations, keeping only the last ($keep_generations) generations($NC)"
    let response = (input "Continue? (y/N): ")
    if not ($response | str downcase | str starts-with "y") {
      print $"($YELLOW)🚫 Operation cancelled($NC)"
      return
    }
  }

  let before_size = (do { ^du -sb /nix/store } | complete | get stdout | str trim | split row "\t" | get 0? | default "0" | into int)

  # Remove old profile generations
  print $"($YELLOW)🗑️ Cleaning profile generations \(keeping last ($keep_generations)\)($NC)"

  # Clean home-manager profile generations
  let hm_profile = "~/.local/state/nix/profiles/home-manager"
  let hm_result = (^nix profile history --profile $hm_profile 2>/dev/null | complete)
  if $hm_result.exit_code == 0 {
    let hm_versions = ($hm_result.stdout | lines | where {|line| $line | str contains "Version"} | each {|line| $line | parse "Version {version}" | get version.0} | sort -r)
    let hm_to_remove = ($hm_versions | skip $keep_generations)

    for version in $hm_to_remove {
      if $verbose { print $"($YELLOW)│ Removing home-manager generation ($version)($NC)" }
      let remove_result = (^nix profile remove --profile $hm_profile $version 2>/dev/null | complete)
      if $remove_result.exit_code != 0 and $verbose {
        print $"($RED)│ Failed to remove home-manager generation ($version)($NC)"
      }
    }
  }

  # Clean system profile generations
  let sys_profile = "~/.local/state/nix/profiles/profile"
  let sys_result = (^nix profile history --profile $sys_profile 2>/dev/null | complete)
  if $sys_result.exit_code == 0 {
    let sys_versions = ($sys_result.stdout | lines | where {|line| $line | str contains "Version"} | each {|line| $line | parse "Version {version}" | get version.0} | sort -r)
    let sys_to_remove = ($sys_versions | skip $keep_generations)

    for version in $sys_to_remove {
      if $verbose { print $"($YELLOW)│ Removing system profile generation ($version)($NC)" }
      let remove_result = (^nix profile remove --profile $sys_profile $version 2>/dev/null | complete)
      if $remove_result.exit_code != 0 and $verbose {
        print $"($RED)│ Failed to remove system profile generation ($version)($NC)"
      }
    }
  }

  print $"($GREEN)✅ Profile generation cleanup complete($NC)"

  # Run garbage collection
  print $"($YELLOW)🗑️ Running store garbage collection($NC)"
  let gc_result = if $verbose {
    let result = (do { ^nix-store --gc } | complete)
    if ($result.stdout | str length) > 0 { print $result.stdout }
    $result
  } else {
    (do { ^nix-store --gc } | complete)
  }

  if $gc_result.exit_code == 0 {
    print $"($GREEN)✅ Store garbage collection complete($NC)"
  } else {
    print $"($RED)❌ Store garbage collection failed($NC)"
    if ($gc_result.stderr | str length) > 0 { print $gc_result.stderr }
  }

  # Optimize store if requested
  if $optimize {
    print $"($YELLOW)⚡ Optimizing store \(hard-linking identical files\)($NC)"
    print $"($YELLOW)├─ ⏱️  This operation may take several minutes for large stores...($NC)"
    let current_store_size = (do { ^du -sh /nix/store } | complete | get stdout | str trim | split row "\t" | get 0? | default "Unknown")
    print $"($YELLOW)├─ 📊 Current store size: ($current_store_size)($NC)"
    print $"($YELLOW)└─ 🔄 Running optimization with progress indicators...($NC)"

    let optimize_result = if $verbose {
      let result = (do { ^nix-store --optimise -vv } | complete)
      # Show the progress output
      if ($result.stdout | str length) > 0 { print $result.stdout }
      if ($result.stderr | str length) > 0 { print $result.stderr }
      $result
    } else {
      let result = (do { ^nix-store --optimise -v } | complete)
      # Show summary info even in non-verbose mode
      if ($result.stderr | str length) > 0 {
        # Extract the final savings summary from stderr
        let summary_lines = ($result.stderr | lines | where {|line| $line | str contains "freed by hard-linking"})
        for line in $summary_lines {
          print $"($GREEN)📊 ($line)($NC)"
        }
      }
      $result
    }

    if $optimize_result.exit_code == 0 {
      print $"($GREEN)✅ Store optimization complete($NC)"
      # Show new store size
      let new_store_size = (do { ^du -sh /nix/store } | complete | get stdout | str trim | split row "\t" | get 0? | default "Unknown")
      print $"($GREEN)📊 New store size: ($new_store_size)($NC)"
    } else {
      print $"($RED)❌ Store optimization failed($NC)"
      if ($optimize_result.stderr | str length) > 0 { print $optimize_result.stderr }
    }
  }

  # Calculate space freed
  let after_size = (do { ^du -sb /nix/store } | complete | get stdout | str trim | split row "\t" | get 0? | default "0" | into int)
  let freed = ($before_size - $after_size)
  let freed_mb = ($freed / 1024 / 1024)

  print $"($GREEN)✅ Smart garbage collection complete!($NC)"
  if $freed > 0 {
    print $"($GREEN)💾 Space freed: ($freed_mb) MB($NC)"
  } else {
    print $"($YELLOW)💾 No space was freed \(store may have grown during operation\)($NC)"
  }
}

# Functions are available when used as a module
