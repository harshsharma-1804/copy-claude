# Twin registry — Obsidian (Windows)
$APP_DISPLAY_NAME = "Obsidian"

function windows_candidates {
    @(
        "$env:LOCALAPPDATA\Programs\obsidian\Obsidian.exe",
        "$env:ProgramFiles\Obsidian\Obsidian.exe"
    )
}
