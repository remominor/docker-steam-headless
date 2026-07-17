#!/usr/bin/env bash
set -e

echo "**** Configuring ProtonUp-Qt via Flatpak ****"

if flatpak --user info net.davidotek.pupgui2 >/dev/null 2>&1; then
    echo "ProtonUp-Qt is already installed"
    exit 0
fi

# Install ProtonUp-Qt
flatpak --user remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak --user install --assumeyes flathub net.davidotek.pupgui2

# Configure ProtonUp-Qt
echo "Configure ProtonUp-Qt..."
sed -i 's/^Categories=.*$/Categories=Utility;/' \
    "${USER_HOME:?}/.local/share/flatpak/exports/share/applications/net.davidotek.pupgui2.desktop"

echo "DONE"
