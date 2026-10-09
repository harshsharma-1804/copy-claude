#!/usr/bin/env bash
# Twin app registry — Claude Desktop

APP_DISPLAY_NAME="Claude"

macos_candidates() {
    echo "/Applications/Claude.app"
}

linux_candidates() {
    echo "/opt/Claude/claude"
    echo "/usr/bin/claude"
    echo "/usr/local/bin/claude"
    echo "$HOME/.local/bin/claude"
    echo "/snap/bin/claude"
}

windows_candidates() {
    echo "$LOCALAPPDATA\\AnthropicClaude\\Claude.exe"
    echo "$PROGRAMFILES\\Claude\\Claude.exe"
    echo "$LOCALAPPDATA\\Programs\\Claude\\Claude.exe"
}
