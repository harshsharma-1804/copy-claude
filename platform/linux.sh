#!/usr/bin/env bash
# Twin — Linux platform implementation

PROFILE_BASE="$HOME/.config/twin"
DESKTOP_DIR="$HOME/.local/share/applications"
BIN_DIR="$HOME/.local/bin"

_linux_safe_name() {
    echo "$1" | tr ' ' '-' | tr '[:upper:]' '[:lower:]'
}

_linux_launcher_name() {
    local app_key="$1"
    local safe_name="$2"
    echo "twin-${app_key}-${safe_name}"
}

_linux_profile_dir() {
    local app_key="$1"
    local safe_name="$2"
    echo "$PROFILE_BASE/${app_key}/${safe_name}"
}

_linux_find_app() {
    local registry_file="$1"
    # shellcheck source=/dev/null
    source "$registry_file"
    while IFS= read -r candidate; do
        candidate=$(eval echo "$candidate")
        [[ -x "$candidate" ]] && echo "$candidate" && return 0
    done < <(linux_candidates)

    # AppImage fallback
    local appimage
    appimage=$(find "$HOME" -maxdepth 3 -iname "${APP_DISPLAY_NAME}*.AppImage" 2>/dev/null | head -n1)
    [[ -n "$appimage" ]] && echo "$appimage" && return 0

    return 1
}

linux_create() {
    local app_key="$1"
    local profile_name="$2"
    local registry_file="$3"

    # shellcheck source=/dev/null
    source "$registry_file"
    local app_display="$APP_DISPLAY_NAME"

    local safe_name
    safe_name=$(_linux_safe_name "$profile_name")
    local launcher_name
    launcher_name=$(_linux_launcher_name "$app_key" "$safe_name")
    local profile_dir
    profile_dir=$(_linux_profile_dir "$app_key" "$safe_name")
    local launcher_path="$BIN_DIR/$launcher_name"
    local desktop_path="$DESKTOP_DIR/${launcher_name}.desktop"

    local app_bin
    app_bin=$(_linux_find_app "$registry_file") || {
        echo "Error: ${app_display} not found on this system."
        echo "Please install it first, then retry."
        exit 1
    }

    if [[ -f "$launcher_path" ]]; then
        echo "Error: Profile '${profile_name}' for ${app_display} already exists."
        exit 1
    fi

    echo "Creating twin: ${app_display} → ${profile_name}"

    mkdir -p "$profile_dir" "$BIN_DIR" "$DESKTOP_DIR"

    # Shell launcher
    cat > "$launcher_path" << LAUNCHER
#!/usr/bin/env bash
# Twin launcher: ${app_display} — ${profile_name}
exec "$app_bin" --user-data-dir="$profile_dir" "\$@"
LAUNCHER
    chmod +x "$launcher_path"

    # .desktop entry
    cat > "$desktop_path" << DESKTOP
[Desktop Entry]
Version=1.0
Type=Application
Name=${app_display} — ${profile_name}
Comment=Twin profile: ${profile_name}
Exec=$launcher_path %U
Icon=${app_key}
Terminal=false
Categories=Network;
StartupWMClass=${app_display}
DESKTOP

    update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true

    echo "Done."
    echo "  Launcher: $launcher_path"
    echo "  Desktop:  $desktop_path"
    echo "  Profile:  $profile_dir"
    echo ""
    echo "Launch: twin open ${app_key} \"${profile_name}\""
}

linux_open() {
    local app_key="$1"
    local profile_name="$2"
    local registry_file="$3"

    # shellcheck source=/dev/null
    source "$registry_file"
    local app_display="$APP_DISPLAY_NAME"
    local safe_name
    safe_name=$(_linux_safe_name "$profile_name")
    local launcher_path="$BIN_DIR/$(_linux_launcher_name "$app_key" "$safe_name")"

    if [[ ! -f "$launcher_path" ]]; then
        echo "Error: No twin named '${profile_name}' found for ${app_display}."
        echo "Create it with: twin new ${app_key} \"${profile_name}\""
        exit 1
    fi

    nohup "$launcher_path" >/dev/null 2>&1 &
    echo "Opened: ${app_display} — ${profile_name}"
}

linux_remove() {
    local app_key="$1"
    local profile_name="$2"
    local registry_file="$3"

    # shellcheck source=/dev/null
    source "$registry_file"
    local app_display="$APP_DISPLAY_NAME"
    local safe_name
    safe_name=$(_linux_safe_name "$profile_name")
    local launcher_name
    launcher_name=$(_linux_launcher_name "$app_key" "$safe_name")
    local launcher_path="$BIN_DIR/$launcher_name"
    local desktop_path="$DESKTOP_DIR/${launcher_name}.desktop"
    local profile_dir
    profile_dir=$(_linux_profile_dir "$app_key" "$safe_name")

    local removed=0
    [[ -f "$launcher_path" ]] && { rm -f "$launcher_path"; echo "Removed launcher."; removed=1; }
    [[ -f "$desktop_path" ]] && { rm -f "$desktop_path"; removed=1; }

    if [[ -d "$profile_dir" ]]; then
        read -r -p "Also delete profile data at '$profile_dir'? [y/N] " confirm
        [[ "$confirm" =~ ^[Yy]$ ]] && rm -rf "$profile_dir" && echo "Removed profile data."
        removed=1
    fi

    update-desktop-database "$DESKTOP_DIR" 2>/dev/null || true
    [[ $removed -eq 0 ]] && echo "Error: Profile '${profile_name}' not found for ${app_display}." && exit 1
}

linux_list() {
    local app_key="${1:-}"

    echo "Twin profiles (Linux):"
    echo ""

    local found=0
    for launcher in "$BIN_DIR"/twin-*; do
        [[ -f "$launcher" ]] || continue
        grep -q -- '--user-data-dir' "$launcher" 2>/dev/null || continue
        local basename
        basename=$(basename "$launcher")
        # twin-claude-work -> key=claude, safe=work
        local key safe
        key=$(echo "$basename" | sed 's/^twin-//' | cut -d'-' -f1)
        safe=$(echo "$basename" | sed "s/^twin-${key}-//")
        [[ -n "$app_key" && "$key" != "$app_key" ]] && continue
        local profile_dir="$PROFILE_BASE/${key}/${safe}"
        local status="no data"
        [[ -d "$profile_dir" ]] && status="data: $profile_dir"
        echo "  [${key}] ${safe}  ($status)"
        found=1
    done

    if [[ $found -eq 0 ]]; then
        echo "  No profiles found."
        echo "  Create one with: twin new <app> <profile-name>"
        echo "  Example:         twin new claude \"Work\""
    fi
}
