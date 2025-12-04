# Pre-commit Hook Setup

This directory contains scripts for setting up pre-commit hooks that ensure code quality before commits.

## Installation

To install the pre-commit hook, run:

```bash
./scripts/install-pre-commit-hook.sh
```

Or manually copy the hook:

```bash
cp scripts/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

## What the Hook Checks

The pre-commit hook automatically runs the following checks before each commit:

1. **Code Formatting** (`dart format --line-length=120`)
   - Verifies that staged Dart files are properly formatted
   - Uses line length of 120 characters
   - Only checks staged files (fast!)
   - Excludes `lib/l10n/*` (generated localization files)

**Note:** Analysis (`flutter analyze`) is **not** run in the pre-commit hook for speed. Full project analysis runs in CI/CD (GitHub Actions) as a safety net, ensuring code quality while keeping local commits fast.

## What Happens if Checks Fail?

If any check fails, the commit will be **blocked** and you'll see error messages indicating what needs to be fixed.

### Fixing Formatting Issues

If formatting fails, run:

```bash
find . -name "*.dart" -not -path "./lib/l10n/*" -not -path "./.dart_tool/*" | xargs dart format --line-length=120
```

Then stage the formatted files and try committing again.

### Fixing Linting Issues

If linting fails, run:

```bash
flutter analyze
```

Fix the reported issues and try committing again.

## Bypassing the Hook (Not Recommended)

If you absolutely need to bypass the hook (e.g., for an emergency fix), use:

```bash
git commit --no-verify
```

**Warning:** Only use this in exceptional circumstances. The checks exist to maintain code quality.

## Updating the Hook

If the hook is updated in the repository, re-run the installation script:

```bash
./scripts/install-pre-commit-hook.sh
```

