
print_header "Configure Flatpak"

if command -v flatpak >/dev/null 2>&1; then
    # Docker masks and makes several paths below /proc read-only. The NVIDIA
    # runtime can add another submount at /proc/driver/nvidia/params. Any of
    # these nested mounts prevents Flatpak's unprivileged bubblewrap process
    # from mounting the private procfs used by its PID namespace. Cover the
    # runtime-provided tree with a clean procfs in this container's mount
    # namespace, retaining the standard safe procfs mount options. This is the
    # same basic workaround used by upstream, with explicit failure handling.
    print_step_header "Mounting a clean procfs for nested Flatpak sandboxes"
    if ! mount -t proc -o nosuid,nodev,noexec proc /proc; then
        print_warning "Could not mount a clean procfs; Flatpak applications may fail to launch"
    fi

    mkdir -p "${USER_HOME:?}/.local/share/flatpak"
    chown -R "${PUID:?}:${PGID:?}" "${USER_HOME:?}/.local/share/flatpak"

    # A system Flatpak installation lives in /var/lib/flatpak, which is part of
    # the disposable container layer. Configure Flathub for the default user so
    # apps installed by GNOME Software live below the persistent home mount.
    if sudo -u "${USER:?}" env \
        HOME="${USER_HOME:?}" \
        XDG_CONFIG_HOME="${USER_HOME:?}/.config" \
        XDG_DATA_HOME="${USER_HOME:?}/.local/share" \
        XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:?}" \
        flatpak --user remote-add --if-not-exists \
            flathub https://flathub.org/repo/flathub.flatpakrepo; then
        print_step_header "Flathub user remote is available in the persistent home directory"

        # Images built before this migration contain a system Flathub remote.
        # Remove it only after the persistent user remote is ready, preventing
        # GNOME Software from selecting the non-persistent system installation.
        if flatpak remotes --system --columns=name 2>/dev/null | grep -Fxq flathub; then
            print_step_header "Removing non-persistent Flathub system remote"
            flatpak remote-delete --system --force flathub
        fi
    else
        print_warning "Persistent Flathub user remote is unavailable; optional Flatpak installs will be skipped"
    fi
else
    print_warning "Flatpak is not installed"
fi

echo -e "\e[34mDONE\e[0m"
