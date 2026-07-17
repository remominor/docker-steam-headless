
# Configure dbus
print_header "Configure container dbus"

if ([ "${MODE}" != "s" ] && [ "${MODE}" != "secondary" ]); then
    if [[ "${HOST_DBUS}" == "true" ]]; then
        print_step_header "Container configured to use the host dbus";
        # Disable container-owned system services. Starting them against the
        # host system bus would expose container policy and account services to
        # the host.
        sed -i 's|^autostart.*=.*$|autostart=false|' /etc/supervisor.d/dbus.ini
        sed -i 's|^autostart.*=.*$|autostart=false|' /etc/supervisor.d/polkit.ini
        sed -i 's|^autostart.*=.*$|autostart=false|' /etc/supervisor.d/accounts-daemon.ini
    else
        print_step_header "Container configured to run its own dbus";
        # Enable the system bus and the desktop services that depend on it.
        sed -i 's|^autostart.*=.*$|autostart=true|' /etc/supervisor.d/dbus.ini
        sed -i 's|^autostart.*=.*$|autostart=true|' /etc/supervisor.d/polkit.ini
        sed -i 's|^autostart.*=.*$|autostart=true|' /etc/supervisor.d/accounts-daemon.ini
        # Remove old dbus session
        rm -rf "${USER_HOME}/.dbus/session-bus/"* 2>/dev/null || true
        # Remove old dbus pids
        mkdir -p /var/run/dbus
        chown root:messagebus /var/run/dbus
        chmod 0755 /var/run/dbus
        # Generate one stable machine ID per container filesystem.
        dbus-uuidgen --ensure=/etc/machine-id
        mkdir -p /var/lib/dbus
        ln -sfn /etc/machine-id /var/lib/dbus/machine-id
        # Remove old lockfiles
        find /var/run/dbus -name "pid" -exec rm -f {} \;
    fi
else
    print_step_header "Dbus service not available when container is run in 'secondary' mode."
    sed -i 's|^autostart.*=.*$|autostart=false|' /etc/supervisor.d/dbus.ini
    sed -i 's|^autostart.*=.*$|autostart=false|' /etc/supervisor.d/polkit.ini
    sed -i 's|^autostart.*=.*$|autostart=false|' /etc/supervisor.d/accounts-daemon.ini
fi

echo -e "\e[34mDONE\e[0m"
