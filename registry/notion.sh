#!/usr/bin/env bash
# Twin app registry — Notion

APP_DISPLAY_NAME="Notion"

macos_candidates() {
    echo "/Applications/Notion.app"
}

linux_candidates() {
    echo "/opt/notion-app/notion"
    echo "/usr/bin/notion"
    echo "$HOME/.local/bin/notion-app"
    echo "/snap/bin/notion-snap"
}

windows_candidates() {
    echo "$LOCALAPPDATA\\Programs\\Notion\\Notion.exe"
    echo "$PROGRAMFILES\\Notion\\Notion.exe"
}
