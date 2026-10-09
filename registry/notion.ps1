# Twin registry — Notion (Windows)
$APP_DISPLAY_NAME = "Notion"

function windows_candidates {
    @(
        "$env:LOCALAPPDATA\Programs\Notion\Notion.exe",
        "$env:ProgramFiles\Notion\Notion.exe"
    )
}
