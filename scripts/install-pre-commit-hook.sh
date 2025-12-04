#!/bin/bash

# Script to install the pre-commit hook
# This ensures all team members have the same pre-commit checks

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK_SOURCE="$PROJECT_ROOT/scripts/pre-commit"
HOOK_DEST="$PROJECT_ROOT/.git/hooks/pre-commit"

if [ ! -d "$PROJECT_ROOT/.git" ]; then
  echo "Error: Not a git repository"
  exit 1
fi

if [ ! -f "$HOOK_SOURCE" ]; then
  echo "Error: Pre-commit hook source not found at $HOOK_SOURCE"
  exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p "$PROJECT_ROOT/.git/hooks"

# Copy the hook
cp "$HOOK_SOURCE" "$HOOK_DEST"
chmod +x "$HOOK_DEST"

echo "✓ Pre-commit hook installed successfully!"
echo "  The hook will check:"
echo "  - Code formatting (dart format --line-length=120) on staged files only"
echo "  Note: Full analysis runs in CI/CD for speed"

