#!/usr/bin/env bash
# Twin — macOS platform implementation
# Creates AppleScript .app launchers that point to the real app binary

APPS_DIR="/Applications"
PROFILE_BASE="$HOME/Library/Application Support/Twin"

_macos_safe_name() {
    # "My Work" -> "My-Work"
    echo "$1" | tr ' ' '-'
}

_macos_app_label() {
    # "claude" + "Work" -> "Claude Work"
    local app_display="$1"
    local profile_name="$2"
    echo "${app_display} ${profile_name}"
}

_macos_app_path() {
    local app_display="$1"
    local profile_name="$2"
    echo "$APPS_DIR/$(_macos_app_label "$app_display" "$profile_name").app"
}

_macos_profile_dir() {
    local app_key="$1"
    local safe_name="$2"
    echo "$PROFILE_BASE/${app_key}/${safe_name}"
}

# Find the real app — checks registry candidates then common fallbacks
_macos_find_app() {
    local app_key="$1"
    local registry_file="$2"

    # Load registry candidates
    # shellcheck source=/dev/null
    source "$registry_file"

    while IFS= read -r candidate; do
        [[ -d "$candidate" || -f "$candidate" ]] && echo "$candidate" && return 0
    done < <(macos_candidates)

    return 1
}

macos_create() {
    local app_key="$1"
    local profile_name="$2"
    local registry_file="$3"

    # Load registry to get display name and candidates
    # shellcheck source=/dev/null
    source "$registry_file"

    local app_display="$APP_DISPLAY_NAME"
    local safe_name
    safe_name=$(_macos_safe_name "$profile_name")
    local app_path
    app_path=$(_macos_app_path "$app_display" "$profile_name")
    local profile_dir
    profile_dir=$(_macos_profile_dir "$app_key" "$safe_name")

    # Find the real installed app
    local real_app=""
    while IFS= read -r candidate; do
        if [[ -d "$candidate" || -x "$candidate" ]]; then
            real_app="$candidate"
            break
        fi
    done < <(macos_candidates)

    if [[ -z "$real_app" ]]; then
        echo "Error: ${app_display} not found on this Mac."
        echo "Please install it first, then retry."
        exit 1
    fi

    if [[ -d "$app_path" ]]; then
        echo "Error: Profile '${profile_name}' for ${app_display} already exists."
        exit 1
    fi

    echo "Creating twin: ${app_display} → ${profile_name}"

    # Use an existing Twin launcher as base (inherits icon), else build fresh
    local base_app=""
    for existing in "$APPS_DIR"/${app_display}\ *.app; do
        [[ -d "$existing" ]] && base_app="$existing" && break
    done

    if [[ -n "$base_app" ]]; then
        cp -r "$base_app" "$app_path"
    else
        local tmp_script
        tmp_script=$(mktemp /tmp/twin-launcher-XXXXXX.applescript)
        echo 'on run' > "$tmp_script"
        echo 'end run' >> "$tmp_script"
        osacompile -o "$app_path" "$tmp_script"
        rm -f "$tmp_script"
    fi

    # Update bundle name
    /usr/libexec/PlistBuddy -c "Set :CFBundleName '${app_display} ${profile_name}'" \
        "$app_path/Contents/Info.plist" 2>/dev/null || \
    /usr/libexec/PlistBuddy -c "Add :CFBundleName string '${app_display} ${profile_name}'" \
        "$app_path/Contents/Info.plist"

    # Write AppleScript launcher
    local tmp_script
    tmp_script=$(mktemp /tmp/twin-launcher-XXXXXX.applescript)

    # .app case (Electron apps like Claude, Notion, Slack)
    if [[ "$real_app" == *.app ]]; then
        cat > "$tmp_script" << APPLESCRIPT
set pidText to do shell script "ps axo pid=,command= | grep -i '[${app_display:0:1}]${app_display:1}' | grep -v -e '--type=' | grep -F '${safe_name}' | awk '{print \$1}' | head -n1"
if pidText is "" then
	do shell script "open -n -a '${real_app}' --args --user-data-dir=\\"${profile_dir}\\""
else
	try
		tell application "System Events" to set frontmost of (first process whose unix id is (pidText as integer)) to true
	end try
end if
APPLESCRIPT
    else
        # Raw binary case
        cat > "$tmp_script" << APPLESCRIPT
set pidText to do shell script "ps axo pid=,command= | grep -i '[${app_display:0:1}]${app_display:1}' | grep -v -e '--type=' | grep -F '${safe_name}' | awk '{print \$1}' | head -n1"
if pidText is "" then
	do shell script "'${real_app}' --user-data-dir=\\"${profile_dir}\\" &"
else
	try
		tell application "System Events" to set frontmost of (first process whose unix id is (pidText as integer)) to true
	end try
end if
APPLESCRIPT
    fi

    osacompile -o "$app_path/Contents/Resources/Scripts/main.scpt" "$tmp_script"
    rm -f "$tmp_script"

    # Create profile data directory
    mkdir -p "$profile_dir"

    echo "Done."
    echo "  App:     $app_path"
    echo "  Profile: $profile_dir"
    echo ""
    echo "Launch: open \"$app_path\""
    echo "  or:   twin open ${app_key} \"${profile_name}\""
}

macos_open() {
    local app_key="$1"
    local profile_name="$2"
    local registry_file="$3"

    source "$registry_file"
    local app_display="$APP_DISPLAY_NAME"
    local app_path
    app_path=$(_macos_app_path "$app_display" "$profile_name")

    if [[ ! -d "$app_path" ]]; then
        echo "Error: No twin named '${profile_name}' found for ${app_display}."
        echo "Create it with: twin new ${app_key} \"${profile_name}\""
        exit 1
    fi

    open "$app_path"
    echo "Opened: ${app_display} — ${profile_name}"
}

macos_remove() {
    local app_key="$1"
    local profile_name="$2"
    local registry_file="$3"

    source "$registry_file"
    local app_display="$APP_DISPLAY_NAME"
    local safe_name
    safe_name=$(_macos_safe_name "$profile_name")
    local app_path
    app_path=$(_macos_app_path "$app_display" "$profile_name")
    local profile_dir
    profile_dir=$(_macos_profile_dir "$app_key" "$safe_name")

    local removed=0

    if [[ -d "$app_path" ]]; then
        rm -rf "$app_path"
        echo "Removed app: $app_path"
        removed=1
    fi

    if [[ -d "$profile_dir" ]]; then
        read -r -p "Also delete profile data at '$profile_dir'? [y/N] " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            rm -rf "$profile_dir"
            echo "Removed profile data."
        else
            echo "Profile data kept."
        fi
        removed=1
    fi

    [[ $removed -eq 0 ]] && echo "Error: Profile '${profile_name}' not found for ${app_display}." && exit 1
}

macos_list() {
    local app_key="${1:-}"
    local filter_display=""

    echo "Twin profiles (macOS):"
    echo ""

    local found=0
    for app in "$APPS_DIR"/*.app; do
        [[ -d "$app" ]] || continue
        local basename
        basename=$(basename "$app" .app)
        # Only list apps that have a profile dir under Twin/
        local matched_key=""
        for reg in "$TWIN_REGISTRY_DIR"/*.sh; do
            [[ -f "$reg" ]] || continue
            # shellcheck source=/dev/null
            source "$reg"
            if [[ "$basename" == "${APP_DISPLAY_NAME} "* ]]; then
                matched_key=$(basename "$reg" .sh)
                break
            fi
        done
        [[ -z "$matched_key" ]] && continue
        [[ -n "$app_key" && "$matched_key" != "$app_key" ]] && continue
        local profile_name="${basename#* }"
        local safe_name
        safe_name=$(echo "$profile_name" | tr ' ' '-')
        local profile_dir="$PROFILE_BASE/${matched_key}/${safe_name}"
        local status="no data"
        [[ -d "$profile_dir" ]] && status="data: $profile_dir"
        echo "  [${matched_key}] ${profile_name}  ($status)"
        found=1
    done

    if [[ $found -eq 0 ]]; then
        echo "  No profiles found."
        echo "  Create one with: twin new <app> <profile-name>"
        echo "  Example:         twin new claude \"Work\""
    fi
}
