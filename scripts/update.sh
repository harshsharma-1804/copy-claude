#!/usr/bin/env bash
# Twin update script — re-downloads all files from GitHub
# Usage: twin update   OR   bash update.sh

set -euo pipefail

REPO="harshsharma-1804/twin"
BRANCH="main"
RAW="https://raw.githubusercontent.com/$REPO/$BRANCH"

# Resolve install location
SOURCE="${BASH_SOURCE[0]}"
while [[ -L "$SOURCE" ]]; do
    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ "$SOURCE" != /* ]] && SOURCE="$DIR/$SOURCE"
done
LIB_DIR="$(cd -P "$(dirname "$SOURCE")/.." && pwd)"

echo "Updating twin from $REPO..."

curl -fsSL "$RAW/bin/twin"             -o "$LIB_DIR/bin/twin"
curl -fsSL "$RAW/platform/macos.sh"    -o "$LIB_DIR/platform/macos.sh"
curl -fsSL "$RAW/platform/linux.sh"    -o "$LIB_DIR/platform/linux.sh"
curl -fsSL "$RAW/registry/claude.sh"   -o "$LIB_DIR/registry/claude.sh"
curl -fsSL "$RAW/registry/notion.sh"   -o "$LIB_DIR/registry/notion.sh"
curl -fsSL "$RAW/registry/slack.sh"    -o "$LIB_DIR/registry/slack.sh"
curl -fsSL "$RAW/registry/obsidian.sh" -o "$LIB_DIR/registry/obsidian.sh"
curl -fsSL "$RAW/registry/discord.sh"  -o "$LIB_DIR/registry/discord.sh"

# Re-fix internal path
sed -i.bak "s|TWIN_ROOT=\"\$(cd \"\$SCRIPT_DIR/..\" && pwd)\"|TWIN_ROOT=\"$LIB_DIR\"|g" \
    "$LIB_DIR/bin/twin" && rm -f "$LIB_DIR/bin/twin.bak"

chmod +x "$LIB_DIR/bin/twin" "$LIB_DIR/platform/macos.sh" "$LIB_DIR/platform/linux.sh"

echo "twin is up to date."
