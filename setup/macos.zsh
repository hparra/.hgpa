#!/usr/bin/env zsh

set -e

echo >&2 "finder hidden files: on"
defaults write com.apple.finder AppleShowAllFiles -bool true
killall Finder >/dev/null 2>&1 || true
