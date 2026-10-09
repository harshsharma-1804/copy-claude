# Twin — Windows platform implementation

$PROFILE_BASE = "$env:APPDATA\Twin"
$SHORTCUTS_DIR = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Twin"
$LAUNCHERS_DIR = "$env:LOCALAPPDATA\Twin\launchers"

function Get-SafeName([string]$name) {
    return ($name -replace '\s+', '-').ToLower()
}

function Get-ProfileDir([string]$appKey, [string]$safeName) {
    return "$PROFILE_BASE\$appKey\$safeName"
}

function Get-LauncherPath([string]$appKey, [string]$safeName) {
    return "$LAUNCHERS_DIR\twin-$appKey-$safeName.bat"
}

function Find-AppBin([string]$registryFile) {
    . $registryFile
    $candidates = windows_candidates
    foreach ($c in $candidates) {
        $expanded = [System.Environment]::ExpandEnvironmentVariables($c)
        # Handle wildcard paths (e.g. Discord app-* folder)
        if ($expanded -match '\*') {
            $found = Get-Item $expanded -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($found) { return $found.FullName }
        } elseif (Test-Path $expanded) {
            return $expanded
        }
    }
    return $null
}

function Twin-Create([string]$appKey, [string]$profileName, [string]$registryFile) {
    . $registryFile
    $appDisplay = $APP_DISPLAY_NAME
    $safeName   = Get-SafeName $profileName
    $profileDir = Get-ProfileDir $appKey $safeName
    $launcherPath = Get-LauncherPath $appKey $safeName
    $shortcutPath = "$SHORTCUTS_DIR\$appDisplay — $profileName.lnk"

    $appBin = Find-AppBin $registryFile
    if (-not $appBin) {
        Write-Error "$appDisplay not found on this system. Install it first."
        exit 1
    }

    if (Test-Path $launcherPath) {
        Write-Error "Profile '$profileName' for $appDisplay already exists."
        exit 1
    }

    Write-Host "Creating twin: $appDisplay -> $profileName"

    New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
    New-Item -ItemType Directory -Force -Path $LAUNCHERS_DIR | Out-Null
    New-Item -ItemType Directory -Force -Path $SHORTCUTS_DIR | Out-Null

    # Batch launcher
    Set-Content -Path $launcherPath -Encoding ASCII -Value @"
@echo off
start "" "$appBin" --user-data-dir="$profileDir" %*
"@

    # Start Menu shortcut
    $shell = New-Object -ComObject WScript.Shell
    $sc = $shell.CreateShortcut($shortcutPath)
    $sc.TargetPath = $appBin
    $sc.Arguments = "--user-data-dir=`"$profileDir`""
    $sc.Description = "Twin: $appDisplay — $profileName"
    $sc.WorkingDirectory = Split-Path $appBin
    $sc.Save()

    Write-Host "Done."
    Write-Host "  Launcher: $launcherPath"
    Write-Host "  Shortcut: $shortcutPath"
    Write-Host "  Profile:  $profileDir"
    Write-Host ""
    Write-Host "Launch: twin open $appKey `"$profileName`""
}

function Twin-Open([string]$appKey, [string]$profileName, [string]$registryFile) {
    . $registryFile
    $appDisplay  = $APP_DISPLAY_NAME
    $safeName    = Get-SafeName $profileName
    $launcherPath = Get-LauncherPath $appKey $safeName

    if (-not (Test-Path $launcherPath)) {
        Write-Error "No twin named '$profileName' found for $appDisplay."
        exit 1
    }
    Start-Process $launcherPath
    Write-Host "Opened: $appDisplay — $profileName"
}

function Twin-Remove([string]$appKey, [string]$profileName, [string]$registryFile) {
    . $registryFile
    $appDisplay   = $APP_DISPLAY_NAME
    $safeName     = Get-SafeName $profileName
    $profileDir   = Get-ProfileDir $appKey $safeName
    $launcherPath = Get-LauncherPath $appKey $safeName
    $shortcutPath = "$SHORTCUTS_DIR\$appDisplay — $profileName.lnk"

    $removed = $false
    if (Test-Path $launcherPath)  { Remove-Item $launcherPath -Force;  Write-Host "Removed launcher."; $removed = $true }
    if (Test-Path $shortcutPath)  { Remove-Item $shortcutPath -Force;  $removed = $true }

    if (Test-Path $profileDir) {
        $confirm = Read-Host "Also delete profile data at '$profileDir'? [y/N]"
        if ($confirm -match '^[Yy]$') { Remove-Item $profileDir -Recurse -Force; Write-Host "Removed profile data." }
        $removed = $true
    }

    if (-not $removed) { Write-Error "Profile '$profileName' not found for $appDisplay."; exit 1 }
}

function Twin-List([string]$appKey = "") {
    Write-Host "Twin profiles (Windows):"
    Write-Host ""

    $found = $false
    if (Test-Path $LAUNCHERS_DIR) {
        Get-ChildItem "$LAUNCHERS_DIR\twin-*.bat" | ForEach-Object {
            $base = $_.BaseName  # twin-claude-work
            $key  = ($base -replace '^twin-', '') -replace '-.*', ''
            $safe = $base -replace "^twin-$key-", ''
            if ($appKey -and $key -ne $appKey) { return }
            $profileDir = "$PROFILE_BASE\$key\$safe"
            $status = if (Test-Path $profileDir) { "data: $profileDir" } else { "no data" }
            Write-Host "  [$key] $safe  ($status)"
            $found = $true
        }
    }

    if (-not $found) {
        Write-Host "  No profiles found."
        Write-Host "  Create one with: twin new <app> <profile-name>"
        Write-Host "  Example:         twin new claude `"Work`""
    }
}
