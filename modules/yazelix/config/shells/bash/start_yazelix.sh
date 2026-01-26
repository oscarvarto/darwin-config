#!/bin/bash
# ~/.config/yazelix/shells/bash/start_yazelix.sh

# Resolve HOME using shell expansion
HOME=$(eval echo ~)
if [ -z "$HOME" ] || [ ! -d "$HOME" ]; then
  echo "Error: Cannot resolve HOME directory"
  exit 1
fi

echo "Resolved HOME=$HOME"

# Set absolute path for Yazelix directory
YAZELIX_DIR="$HOME/.config/yazelix"

# Navigate to Yazelix directory
cd "$YAZELIX_DIR" || { echo "Error: Cannot cd to $YAZELIX_DIR"; exit 1; }

# Run Yazelix directly via Nushell (no devenv).
if ! command -v nu >/dev/null 2>&1; then
  echo "❌ Nushell is required to start Yazelix."
  exit 1
fi

exec nu --login "$YAZELIX_DIR/nushell/scripts/core/start_yazelix.nu" "$HOME"
