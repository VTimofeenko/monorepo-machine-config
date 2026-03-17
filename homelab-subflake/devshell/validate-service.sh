#!/usr/bin/env bash
# Validate a service manifest merge

SERVICE="${1:-}"

if [ -z "$SERVICE" ]; then
  # No argument - use fzf to select
  SERVICE=$(nix eval .#serviceModules --apply 'builtins.attrNames' --json 2>/dev/null \
    | jq -r '.[]' \
    | fzf --prompt="Select service to validate: " --height=40%)

  if [ -z "$SERVICE" ]; then
    echo "No service selected"
    exit 1
  fi
fi

echo "Validating service: $SERVICE"
echo "===================="

# Validate the manifest merges correctly (without JSON to allow functions)
if ! nix eval ".#serviceModules.$SERVICE" > /dev/null 2>&1; then
  echo "❌ Service manifest evaluation failed!"
  nix eval ".#serviceModules.$SERVICE" 2>&1 | tail -20
  exit 1
fi

# Get module count
MODULE_COUNT=$(nix eval ".#serviceModules.$SERVICE.default" --apply 'builtins.length' 2>/dev/null || echo "error")

if [ "$MODULE_COUNT" = "error" ]; then
  echo "❌ Failed to evaluate .default field"
  nix eval ".#serviceModules.$SERVICE.default" 2>&1 | tail -20
  exit 1
fi

# Get sources
HAS_PUBLIC=$(nix eval ".#serviceModules.$SERVICE._sources.hasPublic" 2>/dev/null || echo "unknown")
HAS_PRIVATE=$(nix eval ".#serviceModules.$SERVICE._sources.hasPrivate" 2>/dev/null || echo "unknown")

echo "✅ Service manifest is valid"
echo "   Modules in .default: $MODULE_COUNT"
echo "   Sources: public=$HAS_PUBLIC private=$HAS_PRIVATE"
