#!/bin/bash
# Build Arch Linux package from .deb using debtap
# Run on Arch Linux or in an Arch container

set -e

VERSION="3.0.57"
DEB_FILE="minimax-agent_${VERSION}_amd64.deb"
ARCH_PKG="minimax-agent-${VERSION}-1-x86_64.pkg.tar.zst"

echo "=========================================="
echo "  MiniMax Agent Arch Package Builder"
echo "=========================================="
echo ""

# Check for debtap
if ! command -v debtap &>/dev/null; then
    echo "debtap not found. Installing..."
    sudo pacman -S --needed debtap
    sudo debtap -u
fi

# Check if .deb exists
if [ ! -f "releases/${DEB_FILE}" ]; then
    echo "Error: ${DEB_FILE} not found in releases/"
    echo "Run ./build.sh first to create the .deb package"
    exit 1
fi

# Convert .deb to Arch package
echo "Converting ${DEB_FILE} to Arch package..."
cd releases
debtap -q -p "minimax-agent" -v "${VERSION}" -a "x86_64" -m "ptelgm.yt@gmail.com" -l "MIT" -d "miniMax-agent" -w "https://github.com/unn-Known1/minimax-agent-linux" "../${DEB_FILE}"

# Verify package
if [ -f "${ARCH_PKG}" ]; then
    echo ""
    echo "Package created: releases/${ARCH_PKG}"
    echo "Size: $(du -h ${ARCH_PKG} | cut -f1)"
    echo ""
    echo "Install with:"
    echo "  sudo pacman -U ${ARCH_PKG}"
    echo ""
    echo "Verify contents:"
    echo "  pacman -Qlp ${ARCH_PKG}"
else
    echo "Error: Package creation failed"
    exit 1
fi