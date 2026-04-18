# Nova Nexa

**Nova Nexa** is an automated CLI tool designed to instantly set up and manage a complete, professional **WSL2 Laravel & Full Stack Development Environment** on Windows. 

Originally based on a comprehensive step-by-step guide, Nova Nexa automates the entire process, allowing you to get your development environment up and running in minutes with a single command.

## 🚀 Features

### 1. Automated Environment Setup
Nova Nexa provides a modular, automated installation script that configures your fresh Ubuntu 24.04 WSL2 environment with:
- **Multiple PHP Versions**: 7.4, 8.1, 8.2, 8.3, 8.4 (with easy switching)
- **Database & Cache**: MySQL 8.0, Redis (optional)
- **Web Server**: Nginx with automatic virtual host configuration
- **JavaScript Ecosystem**: Node.js (via NVM)
- **Security**: Trusted local HTTPS using `mkcert`
- **Essential Tools**: Git, Composer, build-essential, curl, unzip

### 2. Powerful CLI Tool (`nexa`)
Once installed, the `nexa` command gives you an interactive REPL interface to manage your projects effortlessly:

| Command | Description |
|---|---|
| `new` | Create a new project (PHP, Laravel, React, Next.js, Vue, etc.) from scratch. Auto-configures SSL, Nginx, and Windows hosts. |
| `attach` | Attach an existing folder (e.g., cloned from Git) to Nginx and generate SSL certificates instantly. |
| `del` | Completely delete a project, including its folder, Nginx config, SSL certs, and hosts entry. |
| `list` | Show a clean, interactive list of all active domains and projects. |

### 3. Utility Commands
- `phpswitch <version>`: Instantly switch the active PHP version for CLI and Composer (e.g., `phpswitch 8.2`).

## ⚙️ Installation

To install Nova Nexa and (optionally) perform the full environment setup, simply open your WSL2 Ubuntu terminal and run:

```bash
curl -sSL https://raw.githubusercontent.com/azrilsyamin/nova-nexa/main/install.sh | bash
```

During installation, you will be prompted:
`Do you want to perform a Full Environment Setup? (y/n)`
- Press **`y`** if this is a fresh WSL2 instance and you need PHP, MySQL, Nginx, etc. installed.
- Press **`n`** if your environment is already set up and you only want to install the `nexa` CLI tool.

## 💻 Usage

Simply type `nexa` in your terminal to open the interactive prompt:

```bash
nexa > help
```

### Creating Projects
From the `nexa` prompt, type `new`:
- `new myapp --cat=dev --laravel=11` (Laravel 11 with PHP 8.2)
- `new frontend --cat=study --react` (React + Vite)
- `new api --cat=staging --express` (Express.js)

*Categories (`dev`, `staging`, `study`) help organize your code in `~/projects/` and determine the local domain (e.g., `myapp.dev.test`).*

### Attaching Existing Projects
If you cloned a project from GitHub:
- `attach myapp --cat=dev` (Auto-detects Laravel/PHP)
- `attach frontend --cat=dev --js --port=5173` (Attaches a Vite JS project)

## 🌐 Windows Hosts Auto-Sync Setup

Instead of manually editing `C:\Windows\System32\drivers\etc\hosts` every time you create a project, this setup uses a PowerShell watcher that automatically syncs domain entries from WSL.

### How It Works

```
WSL (Ubuntu)                         Windows
────────────────────                 ──────────────────────────────
newsite / delsite                    Task Scheduler (runs as SYSTEM)
       │                                        │
       ▼                                        ▼
Writes to shared file      ──────►   Watcher reads every 3s
/mnt/c/wsl-hosts-sync/               Updates hosts file automatically
    pending.txt                       C:\Windows\System32\drivers\etc\hosts
```

> WSL cannot directly edit the Windows hosts file as Admin. The watcher runs as SYSTEM via Task Scheduler — no login prompt needed.

### Step 1: Create Bridge Folder

Open **PowerShell as Administrator** and run:

```powershell
New-Item -ItemType Directory -Force -Path "C:\wsl-hosts-sync"
```

### Step 2: Create PowerShell Watcher Script

> ⚠️ Windows Task Scheduler minimum interval is 1 minute. We use a `while ($true)` loop with `Start-Sleep -Seconds 3` — the task starts once on boot, then the script loops forever.

```powershell
$script = @'
while ($true) {
    $pendingFile = "C:\wsl-hosts-sync\pending.txt"
    $hostsFile   = "C:\Windows\System32\drivers\etc\hosts"
    $logFile     = "C:\wsl-hosts-sync\sync.log"

    function Write-Log {
        param($msg)
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "$timestamp - $msg" | Add-Content -Path $logFile
    }

    if (Test-Path $pendingFile) {
        $lines = Get-Content $pendingFile -ErrorAction SilentlyContinue
        if ($lines) {
            $hostsContent = Get-Content $hostsFile

            foreach ($line in $lines) {
                $line = $line.Trim()
                if ($line -eq "") { continue }

                $parts  = $line -split "\s+"
                $action = $parts[0]
                $domain = $parts[1]
                $ip     = if ($parts[2]) { $parts[2] } else { "127.0.0.1" }

                if ($action -eq "ADD") {
                    $exists = $hostsContent | Where-Object { $_ -match "^\s*[\d.]+\s+$domain\s*$" }
                    if (-not $exists) {
                        Add-Content -Path $hostsFile -Value "$ip $domain"
                        Write-Log "ADDED: $ip $domain"
                    } else {
                        Write-Log "SKIP (already exists): $domain"
                    }
                }
                elseif ($action -eq "REMOVE") {
                    $newContent = $hostsContent | Where-Object { $_ -notmatch "^\s*[\d.]+\s+$domain\s*$" }
                    Set-Content -Path $hostsFile -Value $newContent
                    $hostsContent = $newContent
                    Write-Log "REMOVED: $domain"
                }
            }
            Remove-Item $pendingFile -Force
            Write-Log "Sync complete"
        }
    }
    Start-Sleep -Seconds 3
}
'@

$script | Out-File -FilePath "C:\wsl-hosts-sync\watcher.ps1" -Encoding UTF8
Write-Host "Watcher script created!" -ForegroundColor Green
```

### Step 3: Register Scheduled Task

```powershell
$action = New-ScheduledTaskAction `
    -Execute "PowerShell.exe" `
    -Argument "-NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File C:\wsl-hosts-sync\watcher.ps1"

$trigger = New-ScheduledTaskTrigger -AtStartup

$settings = New-ScheduledTaskSettingsSet `
    -ExecutionTimeLimit (New-TimeSpan -Hours 0) `
    -RestartCount 99 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -MultipleInstances IgnoreNew

$principal = New-ScheduledTaskPrincipal `
    -UserId "SYSTEM" `
    -LogonType ServiceAccount `
    -RunLevel Highest

Register-ScheduledTask `
    -TaskName "WSL-Hosts-Sync" `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Principal $principal `
    -Description "Auto sync WSL domains to Windows hosts file" `
    -Force

Write-Host "Task registered!" -ForegroundColor Green
```

### Step 4: Start Watcher Now (No Reboot Needed)

```powershell
Start-ScheduledTask -TaskName "WSL-Hosts-Sync"
Write-Host "Watcher is running!" -ForegroundColor Cyan
```

### Step 5: Test the Bridge

```powershell
"ADD test-bridge.test 127.0.0.1" | Out-File "C:\wsl-hosts-sync\pending.txt" -Encoding UTF8
Start-Sleep -Seconds 5
Get-Content "C:\Windows\System32\drivers\etc\hosts" | Select-String "test-bridge"
```

You should see: `127.0.0.1 test-bridge.test`. Clean up:

```powershell
"REMOVE test-bridge.test" | Out-File "C:\wsl-hosts-sync\pending.txt" -Encoding UTF8
```

---

## 📁 Project Structure & Categories

Projects are organised by category under `~/projects/`:

```
~/projects/
├── dev/        → active development projects
├── staging/    → staging / pre-production
└── study/      → learning & experiments
```

The category is embedded in the `.test` domain, so projects across categories never clash:

| Category | Path | Domain |
|---|---|---|
| `dev` | `~/projects/dev/<name>` | `<name>.dev.test` |
| `staging` | `~/projects/staging/<name>` | `<name>.staging.test` |
| `study` | `~/projects/study/<name>` | `<name>.study.test` |

---
*Built to simplify WSL2 development workflows.*
