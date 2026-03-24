#!/usr/bin/env bash
set -euo pipefail

# Bump flake inputs with commit trailer support

FIXUP=false
BUMP_ALL=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --fixup)
      FIXUP=true
      shift
      ;;
    --all)
      BUMP_ALL=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: bump-inputs [--all] [--fixup]"
      echo ""
      echo "Options:"
      echo "  --all     Bump all flake inputs (default: only private flake inputs)"
      echo "  --fixup   Squash with previous commit if it has matching Updated-Inputs trailer"
      exit 1
      ;;
  esac
done

if [ "$BUMP_ALL" = true ]; then
  TRAILER_VALUE="all"
  COMMIT_SUMMARY="ci: bump all flake inputs"
  echo "Bumping all flake inputs..."
  UPDATE_ARGS=""
else
  TRAILER_VALUE="private"
  COMMIT_SUMMARY="ci: bump private flake inputs"
  echo "Bumping private flake inputs (data-flake, private-modules)..."
  UPDATE_ARGS="data-flake private-modules"
fi

echo "================================================="

# Run flake update (without committing)
nix flake update $UPDATE_ARGS

# Create commit with ONLY flake.lock (path argument bypasses staging area)
COMMIT_MSG=$(git interpret-trailers --trailer "Updated-Inputs: $TRAILER_VALUE" <<EOF
$COMMIT_SUMMARY
EOF
)
git commit -m "$COMMIT_MSG" flake.lock

echo "✅ Flake inputs bumped with trailer: Updated-Inputs: $TRAILER_VALUE"

# Handle fixup if requested
if [ "$FIXUP" = true ]; then
  echo ""
  echo "Checking for fixup..."

  # Check if previous commit (HEAD~1) has matching Updated-Inputs trailer
  PREV_TRAILER=$(git log -1 HEAD~1 --format="%(trailers:key=Updated-Inputs,valueonly)" 2>/dev/null || true)

  if [ -n "$PREV_TRAILER" ] && [ "$PREV_TRAILER" = "$TRAILER_VALUE" ]; then
    echo "Previous commit has matching Updated-Inputs: $PREV_TRAILER"
    echo "Squashing into previous commit..."
    git reset --soft HEAD~1
    git commit --amend --no-edit
    echo "✅ Commits squashed"
  elif [ -n "$PREV_TRAILER" ]; then
    echo "ℹ️  Previous commit has different Updated-Inputs trailer: $PREV_TRAILER (expected: $TRAILER_VALUE)"
    echo "   Skipping fixup - trailer values must match"
  else
    echo "ℹ️  Previous commit does not have Updated-Inputs trailer, skipping fixup"
    PREV_SUBJECT=$(git log -1 HEAD~1 --pretty=%s 2>/dev/null || echo "N/A")
    echo "   Previous commit: $PREV_SUBJECT"
  fi
fi
