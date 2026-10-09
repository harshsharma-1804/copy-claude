# Twin registry — Slack (Windows)
$APP_DISPLAY_NAME = "Slack"

function windows_candidates {
    @(
        "$env:LOCALAPPDATA\Programs\slack\Slack.exe",
        "$env:ProgramFiles\Slack\Slack.exe"
    )
}
