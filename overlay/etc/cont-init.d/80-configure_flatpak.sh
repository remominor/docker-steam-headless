
print_header "Configure Flatpak"

if command -v flatpak >/dev/null 2>&1; then
    mkdir -p "${USER_HOME:?}/.local/share/flatpak"
    chown -R "${PUID:?}:${PGID:?}" "${USER_HOME:?}/.local/share/flatpak"
    if flatpak remotes --system --columns=name 2>/dev/null | grep -Fxq flathub; then
        print_step_header "Flathub system remote is available"
    else
        print_warning "Flathub system remote is unavailable; optional Flatpak installs will be skipped"
    fi
else
    print_warning "Flatpak is not installed"
fi

echo -e "\e[34mDONE\e[0m"
