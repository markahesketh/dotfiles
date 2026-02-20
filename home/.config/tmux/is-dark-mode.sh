#!/bin/sh
# Exits 0 if dark mode is active, 1 otherwise.
# On non-macOS systems (no `defaults` command), assumes dark mode.
if ! command -v defaults >/dev/null 2>&1; then
  exit 0
fi

defaults read -g AppleInterfaceStyle 2>/dev/null | grep -q Dark
