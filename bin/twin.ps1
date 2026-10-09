# twin.ps1 — run any app with multiple isolated profiles (Windows)
# Usage: .\twin.ps1 <command> <app> [profile-name]

param(
    [Parameter(Position=0)] [string]$Command = "help",
    [Parameter(Position=1)] [string]$AppKey  = "",
    [Parameter(Position=2, ValueFromRemainingArguments=$true)] [string[]]$Rest
)

$VERSION      = "1.0.0"
$TWIN_ROOT    = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$PLATFORM_DIR = Join-Path $TWIN_ROOT "platform"
$REGISTRY_DIR = Join-Path $TWIN_ROOT "registry"

. "$PLATFORM_DIR\windows.ps1"

function Resolve-Registry([string]$key) {
    $key = $key.ToLower()
    $path = Join-Path $REGISTRY_DIR "$key.ps1"
    if (-not (Test-Path $path)) {
        Write-Error "Unknown app '$key'. Run: twin apps  to see supported apps."
        exit 1
    }
    return $path
}

function Show-Usage {
    Write-Host @"
twin v$VERSION — run any app with multiple isolated profiles

Usage:
  .\twin.ps1 new <app> <profile-name>
  .\twin.ps1 open <app> <profile-name>
  .\twin.ps1 remove <app> <profile-name>
  .\twin.ps1 list [app]
  .\twin.ps1 apps
  .\twin.ps1 help

Examples:
  .\twin.ps1 new claude "Work"
  .\twin.ps1 new notion "Client A"
  .\twin.ps1 open claude "Work"
  .\twin.ps1 list
"@
}

$ProfileName = if ($Rest) { $Rest -join " " } else { "" }

switch ($Command.ToLower()) {
    { $_ -in "new","create" } {
        if (-not $AppKey -or -not $ProfileName) { Write-Error "Usage: twin new <app> <profile-name>"; exit 1 }
        $reg = Resolve-Registry $AppKey
        Twin-Create $AppKey.ToLower() $ProfileName $reg
    }
    { $_ -in "open","launch" } {
        if (-not $AppKey -or -not $ProfileName) { Write-Error "Usage: twin open <app> <profile-name>"; exit 1 }
        $reg = Resolve-Registry $AppKey
        Twin-Open $AppKey.ToLower() $ProfileName $reg
    }
    { $_ -in "remove","delete","rm" } {
        if (-not $AppKey -or -not $ProfileName) { Write-Error "Usage: twin remove <app> <profile-name>"; exit 1 }
        $reg = Resolve-Registry $AppKey
        Twin-Remove $AppKey.ToLower() $ProfileName $reg
    }
    { $_ -in "list","ls" } {
        Twin-List $AppKey
    }
    "apps" {
        Write-Host "Supported apps:"
        Get-ChildItem "$REGISTRY_DIR\*.ps1" | ForEach-Object { Write-Host "  $($_.BaseName)" }
    }
    { $_ -in "help","-h","--help" } { Show-Usage }
    { $_ -in "version","-v","--version" } { Write-Host "twin v$VERSION" }
    default { Write-Error "Unknown command '$Command'"; Show-Usage; exit 1 }
}
