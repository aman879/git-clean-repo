#!/usr/bin/env bash

set -e

mkdir -p "$HOME/.local/bin"

cp git-clean.sh "$HOME/.local/bin/git-clean"
chmod +x "$HOME/.local/bin/git-clean"

if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.zshrc"; then
  echo '' >> "$HOME/.zshrc"
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
fi

echo "✅ Installed git-clean."
echo "Run: source ~/.zshrc"