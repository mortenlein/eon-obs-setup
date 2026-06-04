# Eon + OBS Setup

This repo contains a Windows bootstrap script for a fresh PC that needs:

- Git
- Node.js LTS
- OBS Studio
- Eon cloned from GitHub
- Eon started automatically at Windows login
- Eon bound to `0.0.0.0:31982` for LAN access
- Windows Firewall opened for TCP `31982` on Private networks
- Eon's CS2 Game State Integration config copied into the CS2 cfg folder when Steam/CS2 can be found
- OBS scene collection with:
  - `CS2 Game Capture`, targeting `cs2.exe`
  - `Eon HUD`, browser source pointed at `http://localhost:31982/hud/`

## Run

Open PowerShell as Administrator and run:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\Install-EonObs.ps1
```

From GitHub on a fresh PC, use:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
irm https://raw.githubusercontent.com/mortenlein/eon-obs-setup/main/Install-EonObs.ps1 -OutFile Install-EonObs.ps1
.\Install-EonObs.ps1
```

Optional arguments:

```powershell
.\Install-EonObs.ps1 `
  -InstallRoot "C:\Eon" `
  -StartCommand "npm run start" `
  -HostName "0.0.0.0" `
  -Port 31982 `
  -HudUrl "http://localhost:31982/hud/" `
  -ConfigUrl "http://localhost:31982/config"
```

The script opens both Eon URLs in the default browser when setup finishes:

- `http://localhost:31982/hud/`
- `http://localhost:31982/config`

It also prints LAN URLs like:

```text
http://192.168.1.50:31982/hud/
http://192.168.1.50:31982/config
```

## Notes

The OBS scene collection is written to:

```text
%APPDATA%\obs-studio\basic\scenes\Eon CS2.json
```

The startup task is named:

```text
Start Eon HUD
```

The firewall rule is named:

```text
Eon HUD Server 31982
```

If CS2 is installed in a non-standard Steam library and the script cannot find it, pass the cfg folder directly:

```powershell
.\Install-EonObs.ps1 -Cs2CfgPath "D:\SteamLibrary\steamapps\common\Counter-Strike Global Offensive\game\csgo\cfg"
```

If Eon eventually uses a different package manager or start command, pass those in:

```powershell
.\Install-EonObs.ps1 `
  -PackageManager "pnpm" `
  -InstallCommand "pnpm install --frozen-lockfile" `
  -StartCommand "pnpm start"
```
