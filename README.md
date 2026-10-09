# twin

Run any Electron app with multiple isolated profiles — each with its own account, session, and data.

Works on **macOS**, **Linux**, and **Windows**.

---

## The problem

Apps like Claude, Notion, Slack, and Obsidian don't support switching between multiple accounts. Twin fixes this by creating isolated profile launchers — each profile is a fully independent instance of the app.

---

## Install

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/harshsharma-1804/copy-claude/main/scripts/install.sh | bash
```

Restart your terminal (or `source ~/.zshrc`).

### Windows

```powershell
irm https://raw.githubusercontent.com/harshsharma-1804/copy-claude/main/scripts/install.ps1 | iex
```

Restart your terminal after install.

---

## Usage

```bash
# Create profiles
twin new claude "Work"
twin new claude "Personal"
twin new notion "Client A"
twin new slack "Freelance"

# Open a profile
twin open claude "Work"
twin open notion "Client A"

# List all profiles
twin list

# List profiles for one app
twin list claude

# See supported apps
twin apps

# Remove a profile
twin remove claude "Personal"

# Update twin
twin update
```

---

## Supported apps

| Command | App |
|---|---|
| `twin new claude` | Claude Desktop |
| `twin new notion` | Notion |
| `twin new slack` | Slack |
| `twin new obsidian` | Obsidian |
| `twin new discord` | Discord |

### Add any app

Drop a file in `~/.local/lib/twin/registry/<appname>.sh`:

```bash
#!/usr/bin/env bash
APP_DISPLAY_NAME="MyApp"

macos_candidates() { echo "/Applications/MyApp.app"; }
linux_candidates()  { echo "/usr/bin/myapp"; }
windows_candidates(){ echo "$LOCALAPPDATA\\MyApp\\MyApp.exe"; }
```

Then: `twin new myapp "Profile Name"`

---

## How it works

Twin creates a lightweight launcher per profile that passes `--user-data-dir` to the app binary. Each profile gets its own isolated directory, so sessions, history, and settings never mix.

| Platform | What gets created |
|---|---|
| macOS | `.app` launcher in `/Applications/` — appears in Spotlight & Launchpad |
| Linux | Shell script + `.desktop` entry — appears in app launcher |
| Windows | `.bat` launcher + Start Menu shortcut |

App updates apply to all profiles automatically — twin only creates launchers, it never touches the app binary.

---

## Requirements

- The app must be installed from its official source
- macOS 12+, Ubuntu 20.04+, or Windows 10+
- `bash` / `zsh` on macOS/Linux, PowerShell 5+ on Windows

---

## License

MIT
