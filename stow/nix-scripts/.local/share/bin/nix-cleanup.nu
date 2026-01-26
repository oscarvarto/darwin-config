#!/usr/bin/env nu
# Nix cleanup script for managing generations and disk usage

# Colors
const RED = "\u{001b}[0;31m"
const GREEN = "\u{001b}[0;32m"
const YELLOW = "\u{001b}[1;33m"
const BLUE = "\u{001b}[0;34m"
const NC = "\u{001b}[0m"

def show_help [] {
  print $"($BLUE)🧹 Nix Generation Cleanup($NC)"
  print ""
  print "Usage: nix-cleanup [OPTIONS] [COMMAND]"
  print ""
  print "Commands:"
  print "  status           Show current disk usage and generations"
  print "  quick            Quick cleanup (keep last 5 generations)"
  print "  aggressive       Aggressive cleanup (keep last 3 generations)"
  print "  minimal          Minimal cleanup (keep last 10 generations)"
  print "  gc-only          Only run garbage collection"
  print "  custom <N>       Keep last N generations"
  print ""
  print "Options:"
  print "  -h, --help       Show this help message"
  print "  -n, --dry-run    Show what would be cleaned without doing it"
  print "  -f, --force      Skip confirmation prompts"
  print "  -v, --verbose    Show detailed output"
  print ""
  print "Examples:"
  print "  nix-cleanup status"
  print "  nix-cleanup quick"
  print "  nix-cleanup --dry-run aggressive"
  print "  nix-cleanup custom 7"
}

def show_status [] {
  print $"($BLUE)📊 Nix Store Status($NC)"
  
  let store_size = (do { ^du -sh /nix/store } | complete | get stdout | str trim | split row "\t" | get 0? | default "Unknown")
  print $"($YELLOW)├─ Store size:($NC) ($store_size)"
  
  print $"($YELLOW)├─ User generations:($NC)"
  let generations = (^nix-env --list-generations | lines | last 10)
  for gen in $generations {
    print $"($YELLOW)│  ($gen)($NC)"
  }
  
  # System generations (simplified for now)
  print $"($YELLOW)├─ System generations: Available via nix-darwin($NC)"
  
  print $"($YELLOW)└─ Garbage collection preview:($NC)"
  let gc_info = (do { ^nix store gc --dry-run } | complete)
  let gc_lines = if $gc_info.exit_code == 0 { ($gc_info.stdout | lines | length) } else { 0 }
  print $"($YELLOW)   ($gc_lines) store paths would be deleted($NC)"
}

def cleanup_generations [keep_count: int, dry_run: bool, force: bool] {
  print $"($BLUE)🧹 Cleaning up generations keeping last ($keep_count)($NC)"
  
  let total_gens = (^nix-env --list-generations | lines | length)
  let to_delete = ($total_gens - $keep_count)
  
  if $to_delete <= 0 {
    print $"($GREEN)✅ No generations to clean - have ($total_gens), keeping ($keep_count)($NC)"
    return
  }
  
  print $"($YELLOW)📋 Will delete ($to_delete) old generations($NC)"
  
  if $dry_run {
    print $"($BLUE)💭 DRY RUN: Would delete the oldest ($to_delete) generations($NC)"
    let gens_to_show = (^nix-env --list-generations | lines | first $to_delete)
    for gen in $gens_to_show {
      print $"($RED)│  Would delete: ($gen)($NC)"
    }
    return
  }
  
  if not $force {
    print $"($YELLOW)⚠️ This will delete ($to_delete) old generations($NC)"
    let response = (input "Continue? (y/N): ")
    if not ($response | str downcase | str starts-with "y") {
      print $"($YELLOW)🚫 Operation cancelled($NC)"
      return
    }
  }
  
  # Delete old generations
  let gens_to_delete = (^nix-env --list-generations | lines | first $to_delete | each { |line| $line | parse "{gen} *" | get gen.0 } | str join " ")
  if ($gens_to_delete | str trim | is-not-empty) {
    print $"($BLUE)🗑️ Deleting generations: ($gens_to_delete)($NC)"
    ^nix-env --delete-generations $gens_to_delete
    print $"($GREEN)✅ Deleted ($to_delete) generations($NC)"
  }
}

def run_gc [dry_run: bool, verbose: bool] {
  let age_limit = "3d"  # Default to 3 days if not specified
  
  print $"($BLUE)🗑️ Running garbage collection keeping items newer than ($age_limit)($NC)"
  
  let before_size = (do { ^du -sb /nix/store } | complete | get stdout | str trim | split row "\t" | get 0? | into int | default 0)
  
  if $dry_run {
    print $"($BLUE)💭 DRY RUN: Garbage collection preview($NC)"
    ^nix-collect-garbage --dry-run --delete-older-than $age_limit
  } else {
    if $verbose {
      ^nix-collect-garbage --delete-older-than $age_limit
    } else {
      ^nix-collect-garbage --delete-older-than $age_limit | ignore
    }
    
    let after_size = (do { ^du -sb /nix/store } | complete | get stdout | str trim | split row "\t" | get 0? | into int | default 0)
    let freed = ($before_size - $after_size)
    let freed_mb = ($freed / 1024 / 1024)
    
    print $"($GREEN)✅ Garbage collection complete($NC)"
    print $"($GREEN)💾 Freed: ($freed_mb)MB($NC)"
  }
}

# Main logic
def main [
  command?: string = "status"
  count?: int
  --dry-run (-n)
  --force (-f)
  --verbose (-v)
  --help (-h)
] {
  if $help {
    show_help
    return
  }
  
  match $command {
    "status" => { show_status }
    "quick" => { 
      cleanup_generations 5 $dry_run $force
      if not $dry_run { run_gc $dry_run $verbose }
    }
    "aggressive" => { 
      cleanup_generations 3 $dry_run $force
      if not $dry_run { run_gc $dry_run $verbose }
    }
    "minimal" => { 
      cleanup_generations 10 $dry_run $force
      if not $dry_run { run_gc $dry_run $verbose }
    }
    "gc-only" => { run_gc $dry_run $verbose }
    "custom" => { 
      if $count == null {
        print $"($RED)❌ custom command requires a number($NC)"
        show_help
        exit 1
      }
      cleanup_generations $count $dry_run $force
      if not $dry_run { run_gc $dry_run $verbose }
    }
    _ => {
      print $"($RED)❌ Unknown command: ($command)($NC)"
      show_help
      exit 1
    }
  }
}
