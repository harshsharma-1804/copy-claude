#!/usr/bin/env bash
# Twin app registry — Slack

APP_DISPLAY_NAME="Slack"

macos_candidates() {
    echo "/Applications/Slack.app"
}

linux_candidates() {
    echo "/usr/bin/slack"
    echo "/snap/bin/slack"
    echo "/usr/local/bin/slack"
    echo "$HOME/.local/bin/slack"
}

windows_candidates() {
    echo "$LOCALAPPDATA\\Programs\\slack\\Slack.exe"
    echo "$PROGRAMFILES\\Slack\\Slack.exe"
}
