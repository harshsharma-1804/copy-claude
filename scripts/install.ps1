# Twin install script — Windows
# One-liner: irm https://raw.githubusercontent.com/harshsharma-1804/twin/main/scripts/install.ps1 | iex

$REPO    = "harshsharma-1804/twin"
$BRANCH  = "main"
$RAW     = "https://raw.githubusercontent.com/$REPO/$BRANCH"
$LIB_DIR = "$env:LOCALAPPDATA\Twin"
$BIN_DIR = "$env:LOCALAPPDATA\Twin\bin"

Write-Host "Installing twin..."

# Create directories
foreach ($d in @($LIB_DIR, "$LIB_DIR\bin", "$LIB_DIR\platform", "$LIB_DIR\registry", "$LIB_DIR\scripts")) {
    New-Item -ItemType Directory -Force -Path $d | Out-Null
}

# Download files
$files = @{
    "bin/twin.ps1"              = "$LIB_DIR\bin\twin.ps1"
    "platform/windows.ps1"      = "$LIB_DIR\platform\windows.ps1"
    "registry/claude.ps1"       = "$LIB_DIR\registry\claude.ps1"
    "registry/notion.ps1"       = "$LIB_DIR\registry\notion.ps1"
    "registry/slack.ps1"        = "$LIB_DIR\registry\slack.ps1"
    "registry/obsidian.ps1"     = "$LIB_DIR\registry\obsidian.ps1"
    "registry/discord.ps1"      = "$LIB_DIR\registry\discord.ps1"
}

foreach ($src in $files.Keys) {
    Invoke-WebRequest "$RAW/$src" -OutFile $files[$src]
}

# Create twin.bat wrapper (so it works from cmd.exe and regular terminal)
Set-Content -Path "$BIN_DIR\twin.bat" -Encoding ASCII -Value @"
@echo off
powershell -ExecutionPolicy Bypass -File "$LIB_DIR\bin\twin.ps1" %*
"@

# Add to PATH
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*$BIN_DIR*") {
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$BIN_DIR", "User")
    Write-Host "Added $BIN_DIR to PATH — restart your terminal."
}

Write-Host ""
Write-Host "Done. Try:  twin help"
