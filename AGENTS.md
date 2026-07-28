# Release Update Guide

This document outlines the steps to update the Linux build when a new Windows version of MiniMax Agent / MiniMax Code is released.

## Maintainer

- **GitHub:** unn-Known1
- **Email:** ptelgm.yt@gmail.com

## Prerequisites

- Linux system with `dpkg-deb`, `fakeroot`, `npm`, `npx`, and `7z` (p7zip-full) installed
- Access to the Windows .exe release URL
- Git access to this repository

## Step-by-Step Release Process

### 1. Download the Windows .exe Release

```bash
mkdir -p /tmp/minimax-extract
cd /tmp/minimax-extract
curl -fsSL -o "MiniMax Code Setup <VERSION>.exe" "<EXE_URL>"
```

### 2. Extract the .exe Archive

NSIS installers can be extracted with 7z:

```bash
mkdir -p extracted
7z x -oextracted "MiniMax Code Setup <VERSION>.exe"
```

Then extract the app archive (use `app-64.7z` for amd64):

```bash
mkdir -p app-64
7z x -oapp-64 extracted/\$PLUGINSDIR/app-64.7z
```

### 3. Update Version References

Update the version in all relevant files:

| File | Field to Update |
|------|----------------|
| `build.sh` | `VERSION="X.X.X"` |
| `setup.sh` | `VERSION="X.X.X"` |
| `releases/download.sh` | `VERSION`, `GITHUB_URL` |
| `README.md` | Version badge, download URLs, install commands, date |
| `INSTALL.md` | Install command |
| `CONTRIBUTING.md` | alien command example |
| `linux-build/DEBIAN/control` | `Version: X.X.X` |
| `linux-build/opt/minimax-agent/resources/resources/daemon/package.json` | `version` |

### 4. Update Linux Build Resources

Copy the new files from the extracted Windows release:

```bash
# app.asar (main application code)
cp /tmp/minimax-extract/app-64/resources/app.asar \
   linux-build/opt/minimax-agent/resources/app.asar

# app.asar.unpacked (native modules)
rm -rf linux-build/opt/minimax-agent/resources/app.asar.unpacked
cp -r /tmp/minimax-extract/app-64/resources/app.asar.unpacked \
      linux-build/opt/minimax-agent/resources/app.asar.unpacked

# Update tray icons and resources
cp /tmp/minimax-extract/app-64/resources/app-update.yml \
   linux-build/opt/minimax-agent/resources/app-update.yml
cp /tmp/minimax-extract/app-64/resources/resources/icon.ico \
   linux-build/opt/minimax-agent/resources/resources/icon.ico
cp /tmp/minimax-extract/app-64/resources/resources/tray.ico \
   linux-build/opt/minimax-agent/resources/resources/tray.ico
cp /tmp/minimax-extract/app-64/resources/resources/tray.png \
   linux-build/opt/minimax-agent/resources/resources/tray.png
cp /tmp/minimax-extract/app-64/resources/resources/trayTemplate@2x.png \
   linux-build/opt/minimax-agent/resources/resources/trayTemplate@2x.png
cp /tmp/minimax-extract/app-64/resources/resources/trayTemplate.png \
   linux-build/opt/minimax-agent/resources/resources/trayTemplate.png
```

### 5. Build the .deb Package

```bash
cd /root/minimax-agent-linux
sudo ./build.sh
```

The script will:
- Check build dependencies
- Rebuild `better-sqlite3` native module for Electron ABI
- Build the .deb package in `output/`
- Verify the package and daemon entry point

### 6. Copy to Releases

```bash
cp output/minimax-agent_<VERSION>_amd64.deb releases/
```

### 7. Create Git Tag and Push

```bash
git add -A
git commit -m "Release v<VERSION>"
git tag -a v<VERSION> -m "Release v<VERSION>"
git push origin main --tags
```

### 8. Create GitHub Release

Create a release on GitHub with the .deb file attached:

```bash
gh release create v<VERSION> releases/minimax-agent_<VERSION>_amd64.deb \
  --title "v<VERSION>" \
  --notes "Release v<VERSION> - Updated from Windows <VERSION>"
```

### 9. Clean Up

```bash
rm -rf /tmp/minimax-extract
```

## Key Files Reference

| Path | Purpose |
|------|---------|
| `linux-build/DEBIAN/control` | Package metadata (name, version, dependencies) |
| `linux-build/DEBIAN/postinst` | Post-install script (permissions, protocol handlers, daemon setup) |
| `linux-build/DEBIAN/prerm` | Pre-remove script (cleanup systemd units) |
| `linux-build/usr/bin/minimax-agent` | Application launcher script |
| `linux-build/usr/share/applications/minimax-agent.desktop` | Desktop integration file |
| `linux-build/opt/minimax-agent/resources/app.asar` | Main Electron application |
| `linux-build/opt/minimax-agent/resources/app.asar.unpacked/` | Native Node.js modules |
| `build.sh` | Build script |
| `setup.sh` | Post-install setup script (downloads Electron runtime) |

## Native Modules

The following native modules are bundled in `app.asar.unpacked`:

- `better-sqlite3` — SQLite database (rebuilt for Electron ABI during build)
- `node-pty` — Terminal emulation
- `@nut-tree/libnut-linux` — Screen automation
- `clipboardy` — Clipboard access
- `jszip` — ZIP archive handling

## Electron Version

The build targets Electron `v33.2.0`. The `setup.sh` script downloads this runtime during installation.

## Arch Linux Package

Build an Arch Linux package (`.pkg.tar.zst`) from the `.deb` using `debtap`:

**Prerequisites:** Arch Linux system (or Arch container/VM) with `debtap` and `pacman`

```bash
# Install debtap
sudo pacman -S debtap
sudo debtap -u

# Build Arch package from .deb (run on Arch Linux)
cd /path/to/minimax-agent-linux
./build-arch.sh
```

The script creates `releases/minimax-agent-<VERSION>-1-x86_64.pkg.tar.zst`

**Include in GitHub Release:**
```bash
gh release upload v<VERSION> releases/minimax-agent-<VERSION>-1-x86_64.pkg.tar.zst
```

**Arch users install with:**
```bash
sudo pacman -U minimax-agent-<VERSION>-1-x86_64.pkg.tar.zst
```

## Troubleshooting

### Build fails with missing tools
```bash
sudo apt install dpkg-dev fakeroot npm npx
```

### better-sqlite3 rebuild fails
```bash
cd linux-build/opt/minimax-agent/resources/app.asar.unpacked/node_modules/better-sqlite3
npm rebuild
```

### .deb package is corrupt
Verify the package:
```bash
dpkg-deb -I releases/minimax-agent_<VERSION>_amd64.deb
dpkg-deb -c releases/minimax-agent_<VERSION>_amd64.deb | head -20
```
