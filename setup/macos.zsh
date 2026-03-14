#!/usr/bin/env zsh

set -e

echo "macOS recommendations"

echo 'finder: show all files'
defaults write com.apple.finder AppleShowAllFiles -bool true

echo 'finder: show all filename extensions'
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

echo 'finder: show path bar'
defaults write com.apple.finder ShowPathbar -bool true

echo 'finder: show status bar'
defaults write com.apple.finder ShowStatusBar -bool true

echo 'finder: keep folders first when sorting by name'
defaults write com.apple.finder _FXSortFoldersFirst -bool true

killall Finder

echo 'dock: automatically hide and show'
defaults write com.apple.dock autohide -bool true

echo 'dock: do not show recent applications'
defaults write com.apple.dock show-recents -bool false

echo 'dock: minimize windows into application icon'
defaults write com.apple.dock minimize-to-application -bool true

echo 'dock: use scale effect when minimizing'
defaults write com.apple.dock mineffect -string scale

killall Dock
