#!/bin/bash
# Installs the PDC Demo launcher:
#   1. Copies launcher + templates to ~/pdc-demo/
#   2. Puts a .desktop shortcut on the user's desktop
#
# Run from /home/sw/pdc-demo/ (the read-only source).
# Re-run to push updated templates.

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HOME/pdc-demo"

echo "=== Step 1: Copy launcher files to $DEST ==="
mkdir -p "$DEST"
rsync -a --delete \
     --exclude='.git' \
     --exclude='install.sh' \
     --exclude='PDC_launcher.desktop' \
     --exclude='test_*.sh' \
     --exclude='commit_msg.txt' \
     "$SCRIPT_DIR/" "$DEST/"
echo "  OK"

echo ""
echo "=== Step 2: Install desktop shortcut ==="
DESKTOP_DIR="$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")"

# Install icon for the theme
ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
mkdir -p "$ICON_DIR"
cp "$SCRIPT_DIR/icon/pdc-icon.svg" "$ICON_DIR/pdc-demo.svg"
gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true

# Copy .desktop file
cp "$SCRIPT_DIR/PDC_launcher.desktop" "$DESKTOP_DIR/"
chmod +x "$DESKTOP_DIR/PDC_launcher.desktop"

# Trust the .desktop file for XFCE/Thunar
gio set "$DESKTOP_DIR/PDC_launcher.desktop" metadata::trusted true 2>/dev/null || true
gio set "$DESKTOP_DIR/PDC_launcher.desktop" metadata::xfce-exe-checksum \
     "$(sha256sum "$DESKTOP_DIR/PDC_launcher.desktop" | cut -d' ' -f1)" 2>/dev/null || true

# Refresh the desktop
xfdesktop --reload 2>/dev/null || true

echo "  OK"
echo ""
echo "Done! Files at $DEST — re-run install.sh to update."
