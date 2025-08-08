#!/bin/bash

# Script to validate nixd configuration expressions
# Run this before loading the configuration in Emacs

echo "Testing nixd expressions..."

cd /Users/oscarvarto/nixos-config

echo "1. Testing nixpkgs expression..."
nix repl --expr 'import (builtins.getFlake "/Users/oscarvarto/nixos-config").inputs.nixpkgs { }' <<< 'lib.version' 2>/dev/null | head -1

echo "2. Testing darwin configuration options..."
nix repl --expr '(builtins.getFlake "/Users/oscarvarto/nixos-config").darwinConfigurations.predator.options' <<< '_module' 2>/dev/null | head -1

echo "3. Testing home-manager options..."
nix repl --expr '(builtins.getFlake "/Users/oscarvarto/nixos-config").darwinConfigurations.predator.options.home-manager.users.type.getSubOptions []' <<< '_module' 2>/dev/null | head -1

echo "4. Testing NIX_PATH..."
echo $NIX_PATH

echo "5. Testing nixd binary availability..."
which nixd

echo "All tests completed!"
