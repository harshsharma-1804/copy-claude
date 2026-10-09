#!/usr/bin/env bash
# Twin install script — macOS / Linux
# One-liner: curl -fsSL https://raw.githubusercontent.com/harshsharma-1804/copy-claude/main/scripts/install.sh | bash

set -euo pipefail

REPO="harshsharma-1804/copy-claude"
BRANCH="main"
RAW="https://raw.githubusercontent.com/$REPO/$BRANCH"
LIB_DIR="$HOME/.local/lib/twin"
INSTALL_DIR="$HOME/.local/bin"

echo "Installing twin..."

# Create all required directories
mkdir -p "$LIB_DIR/bin" "$LIB_DIR/platform" "$LIB_DIR/registry" "$LIB_DIR/scripts" "$INSTALL_DIR"

# Download files
curl -fsSL "$RAW/bin/twin"                  -o "$LIB_DIR/bin/twin"
curl -fsSL "$RAW/platform/macos.sh"         -o "$LIB_DIR/platform/macos.sh"
curl -fsSL "$RAW/platform/linux.sh"         -o "$LIB_DIR/platform/linux.sh"
curl -fsSL "$RAW/registry/claude.sh"        -o "$LIB_DIR/registry/claude.sh"
curl -fsSL "$RAW/registry/notion.sh"        -o "$LIB_DIR/registry/notion.sh"
curl -fsSL "$RAW/registry/slack.sh"         -o "$LIB_DIR/registry/slack.sh"
curl -fsSL "$RAW/registry/obsidian.sh"      -o "$LIB_DIR/registry/obsidian.sh"
curl -fsSL "$RAW/registry/discord.sh"       -o "$LIB_DIR/registry/discord.sh"
curl -fsSL "$RAW/scripts/update.sh"         -o "$LIB_DIR/scripts/update.sh"

# Fix internal paths to point at installed location
sed -i.bak "s|TWIN_ROOT=\"\$(cd \"\$SCRIPT_DIR/..\" && pwd)\"|TWIN_ROOT=\"$LIB_DIR\"|g" \
    "$LIB_DIR/bin/twin" && rm -f "$LIB_DIR/bin/twin.bak"

# Make executable
chmod +x "$LIB_DIR/bin/twin" \
         "$LIB_DIR/platform/macos.sh" \
         "$LIB_DIR/platform/linux.sh" \
         "$LIB_DIR/scripts/update.sh"

# Symlink into PATH
ln -sf "$LIB_DIR/bin/twin" "$INSTALL_DIR/twin"

echo "Installed: $INSTALL_DIR/twin"
echo "Library:   $LIB_DIR"

# PATH check — auto-add if missing
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    SHELL_RC=""
    [[ "$SHELL" == *"zsh"*  ]] && SHELL_RC="$HOME/.zshrc"
    [[ "$SHELL" == *"bash"* ]] && SHELL_RC="$HOME/.bashrc"

    if [[ -n "$SHELL_RC" ]]; then
        echo '' >> "$SHELL_RC"
        echo '# twin' >> "$SHELL_RC"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
        echo "Added to $SHELL_RC — run: source $SHELL_RC"
    else
        echo "Add to your shell config: export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
fi

echo ""
echo "Done. Try:  twin help"
