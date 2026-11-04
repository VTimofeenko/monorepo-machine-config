#!/usr/bin/env bash
set -euo pipefail

# Rapid iteration loop for host development
# Updates data-flake and deploys on each iteration

HOST="${1:-}"

if [ -z "$HOST" ]; then
  # Use fzf to select host
  HOST=$(nix eval .#nixosConfigurations --apply 'builtins.attrNames' --json 2>/dev/null \
    | jq -r '.[]' \
    | fzf --prompt="Select host for rapid deployment: " --height=40%)

  if [ -z "$HOST" ]; then
    echo "No host selected"
    exit 1
  fi
fi

# Check if deploy command exists
if ! command -v "deploy-$HOST" &> /dev/null; then
  echo "❌ Deploy command 'deploy-$HOST' not found"
  echo "Available deploy commands:"
  compgen -c | grep "^deploy-" || echo "  (none found)"
  exit 1
fi

echo "Starting rapid deployment loop for $HOST"
echo "=========================================="
echo "Press Enter to update data-flake and deploy"
echo "Press Ctrl+C to exit"
echo ""

while true; do
  read -r -p "Press Enter to deploy... "

  echo ""
  echo "[$(date '+%H:%M:%S')] Updating data-flake..."

  if ! nix flake update data-flake; then
    echo "❌ Flake update failed, skipping deployment"
    echo ""
    continue
  fi

  echo "[$(date '+%H:%M:%S')] Deploying to $HOST..."

  if "deploy-$HOST"; then
    echo "✅ Deployment successful"
  else
    echo "❌ Deployment failed"
  fi

  echo ""
done
