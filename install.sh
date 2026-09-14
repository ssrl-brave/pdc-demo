#!/bin/bash
# Installs the PDC Demo launcher on the user's desktop
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DESKTOP_DIR="$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")"

# Install icon for the theme
ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
mkdir -p "$ICON_DIR"
cp "$SCRIPT_DIR/icon/pdc-icon.svg" "$ICON_DIR/pdc-demo.svg"
gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true

# Copy just the .desktop file to the desktop
cp "$SCRIPT_DIR/PDC_launcher.desktop" "$DESKTOP_DIR/"
chmod +x "$DESKTOP_DIR/PDC_launcher.desktop"

# Trust the .desktop file for XFCE/Thunar
gio set "$DESKTOP_DIR/PDC_launcher.desktop" metadata::trusted true 2>/dev/null || true
gio set "$DESKTOP_DIR/PDC_launcher.desktop" metadata::xfce-exe-checksum \
     "$(sha256sum "$DESKTOP_DIR/PDC_launcher.desktop" | cut -d' ' -f1)" 2>/dev/null || true

# Refresh the desktop
xfdesktop --reload 2>/dev/null || true

echo "Done! PDC Demo launcher is on your desktop."
