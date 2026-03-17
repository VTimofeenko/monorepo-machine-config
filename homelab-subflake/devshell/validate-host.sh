#!/usr/bin/env bash
# Validate a host configuration

HOST="${1:-}"

if [ -z "$HOST" ]; then
  # No argument - use fzf to select
  HOST=$(nix eval .#nixosConfigurations --apply 'builtins.attrNames' --json 2>/dev/null \
    | jq -r '.[]' \
    | fzf --prompt="Select host to validate: " --height=40%)

  if [ -z "$HOST" ]; then
    echo "No host selected"
    exit 1
  fi
fi

echo "Validating host: $HOST"
echo "=================="

# Validate the host builds without errors
echo "Running dry-run build..."
if nix build ".#nixosConfigurations.$HOST.config.system.build.toplevel" --dry-run 2>&1; then
  echo ""
  echo "✅ Host configuration is valid"
else
  echo ""
  echo "❌ Host configuration validation failed!"
  echo "Run this to see details:"
  echo "nix build \".#nixosConfigurations.$HOST.config.system.build.toplevel\" --dry-run 2>&1"
  exit 1
fi
