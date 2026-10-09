#!/usr/bin/env bash
# Twin app registry — Discord

APP_DISPLAY_NAME="Discord"

macos_candidates() {
    echo "/Applications/Discord.app"
}

linux_candidates() {
    echo "/usr/bin/discord"
    echo "/snap/bin/discord"
    echo "/usr/local/bin/discord"
    echo "$HOME/.local/bin/discord"
}

windows_candidates() {
    echo "$LOCALAPPDATA\\Discord\\app-*\\Discord.exe"
    echo "$PROGRAMFILES\\Discord\\Discord.exe"
}
