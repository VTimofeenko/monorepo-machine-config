#!/usr/bin/env bash
set -euo pipefail

# Switch private flake inputs (data-flake and private-modules) between local and remote sources

# Check current source type for data-flake
DATA_FLAKE_SOURCE=$(nix flake metadata . --json 2>/dev/null | jq --raw-output '.locks.nodes."data-flake".original.type' || echo "unknown")

echo "Current sources:"
echo "  data-flake: $DATA_FLAKE_SOURCE"

if [ "$DATA_FLAKE_SOURCE" == "path" ]; then
  echo ""
  echo "Switching to remote sources..."
  echo "==============================="

  # Disable local sources
  perl -p -i -e 's/^(\s+)(data-flake\.url.* # LOCAL_SRC$)/\1# \2/' flake.nix
  perl -p -i -e 's/^(\s+)(url = "path.*private-modules.*; # LOCAL_SRC$)/\1# \2/' flake.nix

  # Enable remote sources
  perl -p -i -e 's/^(\s+)# (data-flake\.url.* # REMOTE_SRC$)/\1\2/' flake.nix
  perl -p -i -e 's/^(\s+)# (url = "git\+ssh.*private-modules.*; # REMOTE_SRC$)/\1\2/' flake.nix

  echo "✅ Switched data-flake to remote"
  echo "✅ Switched private-modules to remote"

  # Restore flake.lock on switch to remote
  if git diff --quiet flake.lock 2>/dev/null; then
    echo "ℹ️  flake.lock unchanged"
  else
    git restore flake.lock 2>/dev/null || true
    echo "ℹ️  Restored flake.lock"
  fi

elif [ "$DATA_FLAKE_SOURCE" == "git" ]; then
  echo ""
  echo "Switching to local sources..."
  echo "=============================="

  # Disable remote sources
  perl -p -i -e 's/^(\s+)(data-flake\.url.* # REMOTE_SRC$)/\1# \2/' flake.nix
  perl -p -i -e 's/^(\s+)(url = "git\+ssh.*private-modules.*; # REMOTE_SRC$)/\1# \2/' flake.nix

  # Enable local sources
  perl -p -i -e 's/^(\s+)# (data-flake\.url.* # LOCAL_SRC$)/\1\2/' flake.nix
  perl -p -i -e 's/^(\s+)# (url = "path.*private-modules.*; # LOCAL_SRC$)/\1\2/' flake.nix

  echo "✅ Switched data-flake to local"
  echo "✅ Switched private-modules to local"

else
  echo ""
  echo "❌ Unknown source type: $DATA_FLAKE_SOURCE"
  echo "Cannot determine current state"
  exit 1
fi

echo ""
echo "Verify the changes with: git diff flake.nix"
