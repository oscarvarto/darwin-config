#!/usr/bin/env nu
# Automatic cleanup for regular maintenance
# Designed to be safe for automated execution

# Colors
const GREEN = "\u{001b}[0;32m"
const YELLOW = "\u{001b}[1;33m"
const BLUE = "\u{001b}[0;34m"
const NC = "\u{001b}[0m"

print $"($BLUE)🤖 Nix Auto-Cleanup($NC)"

# Check if store is getting large (>10GB)
let store_size_gb = (do { ^du -sb /nix/store } | complete | get stdout | str trim | split row "\t" | get 0? | into int | default 0 | $in / 1024 / 1024 / 1024)

if $store_size_gb > 10 {
  print $"($YELLOW)⚠️ Store size is ($store_size_gb)GB, running cleanup($NC)"
  
  # Conservative cleanup: keep last 7 generations
  let gen_count = (^nix-env --list-generations | lines | length)
  if $gen_count > 7 {
    print $"($BLUE)🧹 Cleaning old generations \(keeping last 7\)($NC)"
    let old_gens = (^nix-env --list-generations | lines | first ($gen_count - 7) | each { |line| $line | split row " " | get 0 } | str join " ")
    if ($old_gens | str trim | is-not-empty) {
      ^nix-env --delete-generations $old_gens
    }
  }
  
  # Run garbage collection (conservative - keep items newer than 7 days)
  print $"($BLUE)🗑️ Running garbage collection \(keeping items newer than 7d\)($NC)"
  ^nix-collect-garbage --delete-older-than 7d | ignore
  
  let new_size_gb = (do { ^du -sb /nix/store } | complete | get stdout | str trim | split row "\t" | get 0? | into int | default 0 | $in / 1024 / 1024 / 1024)
  let freed_gb = ($store_size_gb - $new_size_gb)
  print $"($GREEN)✅ Cleanup complete. Freed ($freed_gb)GB \(($new_size_gb)GB remaining\)($NC)"
} else {
  print $"($GREEN)✅ Store size is ($store_size_gb)GB, no cleanup needed($NC)"
}
