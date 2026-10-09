#!/usr/bin/env bash
# Twin app registry — Obsidian

APP_DISPLAY_NAME="Obsidian"

macos_candidates() {
    echo "/Applications/Obsidian.app"
}

linux_candidates() {
    echo "/usr/bin/obsidian"
    echo "/opt/obsidian/obsidian"
    echo "/snap/bin/obsidian"
    echo "$HOME/.local/bin/obsidian"
}

windows_candidates() {
    echo "$LOCALAPPDATA\\Programs\\obsidian\\Obsidian.exe"
    echo "$PROGRAMFILES\\Obsidian\\Obsidian.exe"
}
