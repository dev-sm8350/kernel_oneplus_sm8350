#!/bin/bash
#
# EXAMPLES
#   ./install-hook.sh
#

# Download prepare-commit-msg hook
curl -o prepare-commit-msg https://raw.githubusercontent.com/TogoFire/scripts/sh/prepare-commit-msg

# Move hook to .git/hooks directory
mv prepare-commit-msg .git/hooks/prepare-commit-msg

# Make the hook executable
chmod +x .git/hooks/prepare-commit-msg

echo "prepare-commit-msg hook successfully installed!"
