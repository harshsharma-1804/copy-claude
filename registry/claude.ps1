# Twin registry — Claude Desktop (Windows)
$APP_DISPLAY_NAME = "Claude"

function windows_candidates {
    @(
        "$env:LOCALAPPDATA\AnthropicClaude\Claude.exe",
        "$env:LOCALAPPDATA\Programs\Claude\Claude.exe",
        "$env:ProgramFiles\Claude\Claude.exe"
    )
}
