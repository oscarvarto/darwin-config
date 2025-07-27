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
  print "  dry-run          Show what would be deleted (keeping last 3 generations)"
  print "  pin              Pin essential derivations to prevent removal"
  print "  clean [N]        Clean keeping last N generations (default: 3)"
  print "  aggressive       Aggressive cleanup (keep last 2 generations)"
  print "  conservative     Conservative cleanup (keep last 7 generations)"
  print ""
  print "Options:"
  print "  -h, --help       Show this help message"
  print "  -f, --force      Skip confirmation prompts"
  print "  -v, --verbose    Show detailed output"
  print "  --optimize       Run store optimization after cleanup"
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
  print $"($BLUE)💭 Smart GC Dry Run (keeping last ($keep_generations) generations)($NC)"
  
  print $"($YELLOW)📋 What would be cleaned:($NC)"
  print $"($YELLOW)├─ Removing old home-manager generations (older than ($keep_generations) days)($NC)"
  
  let dry_run_cmd = $"nix-collect-garbage --delete-older-than ($keep_generations)d --dry-run"
  let result = (do { ^nix-collect-garbage --delete-older-than $"($keep_generations)d" --dry-run } | complete)
  
  if $result.exit_code == 0 {
    let output_lines = ($result.stdout | lines)
    let removing_lines = ($output_lines | where {|line| $line | str contains "removing"})
    let deleting_lines = ($output_lines | where {|line| $line | str contains "deleting"})
    
    if ($removing_lines | length) > 0 {
      print $"($YELLOW)├─ Profile cleanup:($NC)"
      for line in $removing_lines {
        print $"($YELLOW)│  ($line)($NC)"
      }
    }
    
    if ($deleting_lines | length) > 0 {
      print $"($YELLOW)├─ Store cleanup:($NC)"
      let delete_count = ($deleting_lines | length)
      print $"($YELLOW)│  ($delete_count) store paths would be deleted($NC)"
    }
  }
  
  print $"($YELLOW)└─ No actual changes made - this was a dry run($NC)"
}

def pin_essentials [] {
  print $"($BLUE)📌 Pinning essential derivations to prevent removal($NC)"
  
  let essential_packages = [
    "nixpkgs#git",
    "nixpkgs#curl", 
    "nixpkgs#starship",
    "nixpkgs#helix",
    "nixpkgs#yazi",
    "nixpkgs#zoxide",
    "nixpkgs#atuin",
    "nixpkgs#jujutsu",
    "nixpkgs#lazygit"
  ]
  
  # Create a gcroot for current system configuration if it exists
  let system_derivation = (do { ^nix-instantiate --add-root /nix/var/nix/gcroots/current-system '<nixpkgs/nixos>' -A system } | complete)
  if $system_derivation.exit_code == 0 {
    print $"($GREEN)✅ Pinned current system configuration($NC)"
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
  print $"($BLUE)🧹 Starting smart garbage collection (keeping last ($keep_generations) generations)($NC)"
  
  if not $force {
    print $"($YELLOW)⚠️ This will remove generations older than ($keep_generations) days($NC)"
    let response = (input "Continue? (y/N): ")
    if not ($response | str downcase | str starts-with "y") {
      print $"($YELLOW)🚫 Operation cancelled($NC)"
      return
    }
  }
  
  let before_size = (do { ^du -sb /nix/store } | complete | get stdout | str trim | split row "\t" | get 0? | into int | default 0)
  
  # Remove old generations
  print $"($YELLOW)🗑️ Removing old generations (older than ($keep_generations) days)($NC)"
  let cleanup_result = if $verbose {
    (do { ^nix-collect-garbage --delete-older-than $"($keep_generations)d" } | complete)
  } else {
    (do { ^nix-collect-garbage --delete-older-than $"($keep_generations)d" } | complete)
  }
  
  if $cleanup_result.exit_code == 0 {
    print $"($GREEN)✅ Generation cleanup complete($NC)"
  } else {
    print $"($RED)❌ Generation cleanup failed($NC)"
    print $cleanup_result.stderr
    return
  }
  
  # Run garbage collection
  print $"($YELLOW)🗑️ Running garbage collection($NC)"
  let gc_result = if $verbose {
    (do { ^nix-store --gc } | complete)
  } else {
    (do { ^nix-store --gc } | complete)
  }
  
  if $gc_result.exit_code == 0 {
    print $"($GREEN)✅ Garbage collection complete($NC)"
  } else {
    print $"($RED)❌ Garbage collection failed($NC)"
    print $gc_result.stderr
  }
  
  # Optimize store if requested
  if $optimize {
    print $"($YELLOW)⚡ Optimizing store (hard-linking identical files)($NC)"
    let optimize_result = if $verbose {
      (do { ^nix-store --optimise } | complete)
    } else {
      (do { ^nix-store --optimise } | complete)
    }
    
    if $optimize_result.exit_code == 0 {
      print $"($GREEN)✅ Store optimization complete($NC)"
    } else {
      print $"($RED)❌ Store optimization failed($NC)"
      print $optimize_result.stderr
    }
  }
  
  # Calculate space freed
  let after_size = (do { ^du -sb /nix/store } | complete | get stdout | str trim | split row "\t" | get 0? | into int | default 0)
  let freed = ($before_size - $after_size)
  let freed_mb = ($freed / 1024 / 1024)
  
  print $"($GREEN)✅ Smart garbage collection complete!($NC)"
  if $freed > 0 {
    print $"($GREEN)💾 Space freed: ($freed_mb) MB($NC)"
  } else {
    print $"($YELLOW)💾 No space was freed (store may have grown during operation)($NC)"
  }
}

# Main logic
def main [
  command?: string = "status"
  count?: int
  --force (-f)
  --verbose (-v)
  --help (-h)
  --optimize
] {
  if $help {
    show_help
    return
  }
  
  match $command {
    "status" => { show_status }
    "dry-run" => { perform_dry_run 3 }
    "pin" => { pin_essentials }
    "clean" => { 
      let keep_gens = if $count != null { $count } else { 3 }
      perform_cleanup $keep_gens $force $verbose $optimize
    }
    "aggressive" => { 
      perform_cleanup 2 $force $verbose $optimize
    }
    "conservative" => { 
      perform_cleanup 7 $force $verbose $optimize
    }
    _ => {
      # Check if the command is a number (for backward compatibility)
      let parsed_num = ($command | into int | default null)
      if $parsed_num != null {
        perform_cleanup $parsed_num $force $verbose $optimize
      } else {
        print $"($RED)❌ Unknown command: ($command)($NC)"
        show_help
        exit 1
      }
    }
  }
}
