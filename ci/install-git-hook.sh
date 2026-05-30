#!/usr/bin/env bash
# Installs the Jenkins-triggering git pre-push hook into this repo.
set -euo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Install the pre-push hook (fires when you `git push`).
cp "$REPO_DIR/ci/pre-push" "$REPO_DIR/.git/hooks/pre-push"
chmod +x "$REPO_DIR/.git/hooks/pre-push"
echo "Installed pre-push hook -> $REPO_DIR/.git/hooks/pre-push"

# Clean up the older post-commit hook if it was installed previously.
if [ -f "$REPO_DIR/.git/hooks/post-commit" ]; then
  rm -f "$REPO_DIR/.git/hooks/post-commit"
  echo "Removed obsolete post-commit hook"
fi
