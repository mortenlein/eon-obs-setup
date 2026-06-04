#requires -version 5.1

[CmdletBinding()]
param(
    [string]$EonRepoUrl = "https://github.com/mortenlein/eon.git",

    [string]$InstallRoot = "C:\Eon",
    [string]$EonBranch = "",
    [string]$PackageManager = "npm",
    [string]$InstallCommand = "npm ci",
    [string]$StartCommand = "npm run start",
    [string]$HostName = "0.0.0.0",
    [int]$Port = 31982,
    [string]$HudUrl = "http://localhost:31982/hud/",
    [string]$ConfigUrl = "http://localhost:31982/config",
    [string]$HealthUrl = "http://localhost:31982/api/gsi/status",
    [string]$Cs2CfgPath = "",
    [int]$HudWidth = 1920,
    [int]$HudHeight = 1080,
    [int]$StartupTimeoutSeconds = 60,
    [switch]$SkipFirewallRule,
    [switch]$SkipGsiConfig,
    [switch]$SkipObsConfig,
    [switch]$SkipBrowserOpen
)

$ErrorActionPreference = "Stop"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Test-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-Command {
    param([string]$Name)

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' is not available on PATH."
    }
}

function Install-WingetPackage {
    param(
        [string]$Id,
        [string]$Name
    )

    Write-Step "Installing $Name"
    winget install --id $Id --exact --silent --accept-package-agreements --accept-source-agreements
}

function Update-ProcessPath {
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machinePath;$userPath"
}

function Invoke-InDirectory {
    param(
        [string]$Path,
        [string]$Command
    )

    Push-Location $Path
    try {
        Write-Host "> $Command"
        cmd.exe /c $Command
        if ($LASTEXITCODE -ne 0) {
            throw "Command failed with exit code ${LASTEXITCODE}: $Command"
        }
    }
    finally {
        Pop-Location
    }
}

function Get-ObsScenesPath {
    $path = Join-Path $env:APPDATA "obs-studio\basic\scenes"
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    return Join-Path $path "Eon CS2.json"
}

function Write-ObsSceneCollection {
    param(
        [string]$Path,
        [string]$BrowserUrl,
        [int]$BrowserWidth,
        [int]$BrowserHeight
    )

    $sceneCollection = [ordered]@{
        current_program_scene = "CS2 Eon"
        current_scene = "CS2 Eon"
        current_transition = "Fade"
        groups = @()
        modules = [ordered]@{}
        name = "Eon CS2"
        preview_locked = $false
        quick_transitions = @(
            [ordered]@{
                duration = 300
                fade_to_black = $false
                hotkeys = @()
                id = 1
                name = "Fade"
            }
        )
        saved_projectors = @()
        scaling_cx = 0
        scaling_cy = 0
        scaling_enabled = $false
        sources = @(
            [ordered]@{
                balance = 0.5
                deinterlace_field_order = 0
                deinterlace_mode = 0
                enabled = $true
                flags = 0
                hotkeys = [ordered]@{}
                id = "game_capture"
                mixers = 255
                monitoring_type = 0
                muted = $false
                name = "CS2 Game Capture"
                prev_ver = 520093697
                private_settings = [ordered]@{}
                push_to_mute = $false
                push_to_mute_delay = 0
                push_to_talk = $false
                push_to_talk_delay = 0
                settings = [ordered]@{
                    capture_mode = "window"
                    priority = 2
                    window = "cs2.exe:SDL_app:Counter-Strike 2"
                }
                sync = 0
                versioned_id = "game_capture"
                volume = 1.0
            },
            [ordered]@{
                balance = 0.5
                deinterlace_field_order = 0
                deinterlace_mode = 0
                enabled = $true
                flags = 0
                hotkeys = [ordered]@{}
                id = "browser_source"
                mixers = 255
                monitoring_type = 0
                muted = $false
                name = "Eon HUD"
                prev_ver = 520093697
                private_settings = [ordered]@{}
                push_to_mute = $false
                push_to_mute_delay = 0
                push_to_talk = $false
                push_to_talk_delay = 0
                settings = [ordered]@{
                    css = ""
                    height = $BrowserHeight
                    is_local_file = $false
                    reroute_audio = $false
                    restart_when_active = $false
                    shutdown = $false
                    url = $BrowserUrl
                    width = $BrowserWidth
                }
                sync = 0
                versioned_id = "browser_source"
                volume = 1.0
            },
            [ordered]@{
                balance = 0.5
                deinterlace_field_order = 0
                deinterlace_mode = 0
                enabled = $true
                flags = 0
                hotkeys = [ordered]@{}
                id = "scene"
                mixers = 255
                monitoring_type = 0
                muted = $false
                name = "CS2 Eon"
                prev_ver = 520093697
                private_settings = [ordered]@{}
                push_to_mute = $false
                push_to_mute_delay = 0
                push_to_talk = $false
                push_to_talk_delay = 0
                settings = [ordered]@{
                    custom_size = $false
                    id_counter = 3
                    items = @(
                        [ordered]@{
                            align = 5
                            bounds = [ordered]@{ x = 0.0; y = 0.0 }
                            bounds_align = 0
                            bounds_type = 0
                            crop_bottom = 0
                            crop_left = 0
                            crop_right = 0
                            crop_top = 0
                            group_item_backup = $false
                            hide_transition = [ordered]@{ duration = 300 }
                            id = 1
                            locked = $false
                            name = "CS2 Game Capture"
                            pos = [ordered]@{ x = 0.0; y = 0.0 }
                            private_settings = [ordered]@{}
                            rot = 0.0
                            scale = [ordered]@{ x = 1.0; y = 1.0 }
                            scale_filter = "disable"
                            show_transition = [ordered]@{ duration = 300 }
                            visible = $true
                        },
                        [ordered]@{
                            align = 5
                            bounds = [ordered]@{ x = 0.0; y = 0.0 }
                            bounds_align = 0
                            bounds_type = 0
                            crop_bottom = 0
                            crop_left = 0
                            crop_right = 0
                            crop_top = 0
                            group_item_backup = $false
                            hide_transition = [ordered]@{ duration = 300 }
                            id = 2
                            locked = $false
                            name = "Eon HUD"
                            pos = [ordered]@{ x = 0.0; y = 0.0 }
                            private_settings = [ordered]@{}
                            rot = 0.0
                            scale = [ordered]@{ x = 1.0; y = 1.0 }
                            scale_filter = "disable"
                            show_transition = [ordered]@{ duration = 300 }
                            visible = $true
                        }
                    )
                }
                sync = 0
                versioned_id = "scene"
                volume = 1.0
            }
        )
        transition_duration = 300
        transitions = @(
            [ordered]@{
                id = "fade_transition"
                name = "Fade"
                settings = [ordered]@{}
            }
        )
    }

    $json = $sceneCollection | ConvertTo-Json -Depth 20
    Set-Content -Path $Path -Value $json -Encoding UTF8
}

function Write-EonLauncher {
    param(
        [string]$InstallPath,
        [string]$Command,
        [string]$BindHost,
        [int]$BindPort
    )

    $launcherPath = Join-Path $InstallPath "Start-Eon.ps1"
    $content = @"
`$ErrorActionPreference = "Stop"
`$env:HOST = "$BindHost"
`$env:PORT = "$BindPort"
Set-Location -LiteralPath "$InstallPath"
cmd.exe /c "$Command"
"@
    Set-Content -Path $launcherPath -Value $content -Encoding UTF8
    return $launcherPath
}

function Register-EonTask {
    param([string]$LauncherPath)

    Write-Step "Registering Eon startup task"
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$LauncherPath`""
    $trigger = New-ScheduledTaskTrigger -AtLogOn
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    Register-ScheduledTask -TaskName "Start Eon HUD" -Action $action -Trigger $trigger -Settings $settings -Description "Starts the Eon CS2 HUD at login." -Force | Out-Null
}

function Ensure-FirewallRule {
    param([int]$LocalPort)

    Write-Step "Configuring Windows Firewall"
    $displayName = "Eon HUD Server $LocalPort"
    $existingRule = Get-NetFirewallRule -DisplayName $displayName -ErrorAction SilentlyContinue

    if ($existingRule) {
        $existingRule | Set-NetFirewallRule -Enabled True -Direction Inbound -Action Allow -Profile Private
        $existingRule | Set-NetFirewallPortFilter -Protocol TCP -LocalPort $LocalPort
    }
    else {
        New-NetFirewallRule -DisplayName $displayName -Direction Inbound -Action Allow -Protocol TCP -LocalPort $LocalPort -Profile Private | Out-Null
    }

    Write-Host "Firewall rule enabled for TCP $LocalPort on Private networks."
}

function Wait-ForHttp {
    param(
        [string]$Url,
        [int]$TimeoutSeconds
    )

    Write-Step "Waiting for Eon to respond"
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    $lastError = $null

    while ((Get-Date) -lt $deadline) {
        try {
            Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 3 | Out-Null
            Write-Host "Eon is responding at $Url"
            return $true
        }
        catch {
            $lastError = $_.Exception.Message
            Start-Sleep -Seconds 2
        }
    }

    Write-Warning "Eon did not respond at $Url within $TimeoutSeconds seconds. Last error: $lastError"
    return $false
}

function Get-LanIPv4Addresses {
    Get-NetIPAddress -AddressFamily IPv4 |
        Where-Object {
            $_.IPAddress -notlike "127.*" -and
            $_.IPAddress -notlike "169.254.*" -and
            $_.PrefixOrigin -ne "WellKnown"
        } |
        Select-Object -ExpandProperty IPAddress -Unique
}

function Get-SteamInstallPath {
    $registryPaths = @(
        "HKCU:\Software\Valve\Steam",
        "HKLM:\SOFTWARE\WOW6432Node\Valve\Steam",
        "HKLM:\SOFTWARE\Valve\Steam"
    )

    foreach ($path in $registryPaths) {
        if (Test-Path $path) {
            $props = Get-ItemProperty -Path $path
            if ($props.SteamPath) {
                return $props.SteamPath
            }
            if ($props.InstallPath) {
                return $props.InstallPath
            }
        }
    }

    return ""
}

function Get-SteamLibraryPaths {
    $steamPath = Get-SteamInstallPath
    if (-not $steamPath) {
        return @()
    }

    $libraries = New-Object System.Collections.Generic.List[string]
    $libraries.Add($steamPath)

    $libraryFoldersPath = Join-Path $steamPath "steamapps\libraryfolders.vdf"
    if (Test-Path $libraryFoldersPath) {
        $content = Get-Content -Path $libraryFoldersPath
        foreach ($line in $content) {
            if ($line -match '"path"\s+"([^"]+)"') {
                $libraries.Add($matches[1].Replace("\\", "\"))
            }
        }
    }

    return $libraries | Select-Object -Unique
}

function Find-Cs2CfgPath {
    foreach ($library in Get-SteamLibraryPaths) {
        $candidate = Join-Path $library "steamapps\common\Counter-Strike Global Offensive\game\csgo\cfg"
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    return ""
}

function Install-GsiConfig {
    param(
        [string]$RepoPath,
        [string]$TargetCfgPath
    )

    $source = Join-Path $RepoPath "gamestate_integration_eon.cfg"
    if (-not (Test-Path $source)) {
        Write-Warning "Eon GSI config was not found at $source."
        return
    }

    if (-not $TargetCfgPath) {
        $TargetCfgPath = Find-Cs2CfgPath
    }

    if (-not $TargetCfgPath) {
        Write-Warning "CS2 cfg folder was not found. Copy gamestate_integration_eon.cfg into CS2's game\csgo\cfg folder manually."
        return
    }

    New-Item -ItemType Directory -Path $TargetCfgPath -Force | Out-Null
    Copy-Item -Path $source -Destination (Join-Path $TargetCfgPath "gamestate_integration_eon.cfg") -Force
    Write-Host "GSI config copied to: $TargetCfgPath"
}

if (-not (Test-Admin)) {
    throw "Run this script from an elevated PowerShell window."
}

Assert-Command "winget"

Install-WingetPackage -Id "Git.Git" -Name "Git"
Install-WingetPackage -Id "OpenJS.NodeJS.LTS" -Name "Node.js LTS"
Install-WingetPackage -Id "OBSProject.OBSStudio" -Name "OBS Studio"
Update-ProcessPath

Assert-Command "git"
Assert-Command "node"
Assert-Command $PackageManager

Write-Step "Preparing Eon repo"
if (Test-Path $InstallRoot) {
    if (Test-Path (Join-Path $InstallRoot ".git")) {
        git -C $InstallRoot fetch --all --prune
        if ($EonBranch) {
            git -C $InstallRoot checkout $EonBranch
        }
        git -C $InstallRoot pull --ff-only
    }
    else {
        throw "$InstallRoot already exists but is not a git repository. Pick another -InstallRoot or remove the folder."
    }
}
else {
    if ($EonBranch) {
        git clone --branch $EonBranch $EonRepoUrl $InstallRoot
    }
    else {
        git clone $EonRepoUrl $InstallRoot
    }
}

Write-Step "Installing Eon dependencies"
Invoke-InDirectory -Path $InstallRoot -Command $InstallCommand

if (-not $SkipGsiConfig) {
    Write-Step "Installing CS2 GSI config"
    Install-GsiConfig -RepoPath $InstallRoot -TargetCfgPath $Cs2CfgPath
}

if (-not $SkipFirewallRule) {
    Ensure-FirewallRule -LocalPort $Port
}

$launcher = Write-EonLauncher -InstallPath $InstallRoot -Command $StartCommand -BindHost $HostName -BindPort $Port
Register-EonTask -LauncherPath $launcher

if (-not $SkipObsConfig) {
    Write-Step "Writing OBS scene collection"
    $obsScenePath = Get-ObsScenesPath
    Write-ObsSceneCollection -Path $obsScenePath -BrowserUrl $HudUrl -BrowserWidth $HudWidth -BrowserHeight $HudHeight
    Write-Host "OBS scene collection written to: $obsScenePath"
}

Write-Step "Starting Eon"
Start-Process powershell.exe -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$launcher`"" -WindowStyle Hidden

$eonReady = Wait-ForHttp -Url $HealthUrl -TimeoutSeconds $StartupTimeoutSeconds

if (-not $SkipBrowserOpen) {
    Write-Step "Opening Eon URLs"
    Start-Process $HudUrl
    Start-Process $ConfigUrl
}

Write-Step "Launching OBS"
$obsCandidates = @(
    "${env:ProgramFiles}\obs-studio\bin\64bit\obs64.exe",
    "${env:ProgramFiles(x86)}\obs-studio\bin\64bit\obs64.exe"
)
$obsPath = $obsCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($obsPath) {
    Start-Process -FilePath $obsPath -WorkingDirectory (Split-Path $obsPath)
}
else {
    Write-Warning "OBS was installed, but obs64.exe was not found in the expected location. Start OBS manually."
}

Write-Host ""
Write-Host "Done. Eon HUD: $HudUrl"
Write-Host "Done. Eon config: $ConfigUrl"
$lanIps = @(Get-LanIPv4Addresses)
if ($lanIps.Count -gt 0) {
    Write-Host ""
    Write-Host "LAN URLs:"
    foreach ($ip in $lanIps) {
        Write-Host "HUD:    http://${ip}:$Port/hud/"
        Write-Host "Config: http://${ip}:$Port/config"
    }
}
elseif ($HostName -eq "0.0.0.0") {
    Write-Warning "No LAN IPv4 address was detected. Confirm this PC is connected to the Private LAN."
}

if (-not $eonReady) {
    Write-Warning "Setup finished, but Eon was not confirmed healthy. Check the Start Eon HUD scheduled task or run $launcher manually."
}
