# Twin registry — Discord (Windows)
$APP_DISPLAY_NAME = "Discord"

function windows_candidates {
    @(
        "$env:LOCALAPPDATA\Discord\app-*\Discord.exe",
        "$env:ProgramFiles\Discord\Discord.exe"
    )
}
