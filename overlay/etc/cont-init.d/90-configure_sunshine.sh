
print_header "Configure Sunshine"

if ([ "${MODE}" != "s" ] && [ "${MODE}" != "secondary" ]); then
    if [ "${ENABLE_SUNSHINE:-}" = "true" ]; then
        print_step_header "Enable Sunshine server"
        sed -i 's|^autostart.*=.*$|autostart=true|' /etc/supervisor.d/sunshine.ini
    else
        print_step_header "Disable Sunshine server"
        sed -i 's|^autostart.*=.*$|autostart=false|' /etc/supervisor.d/sunshine.ini
    fi
else
    print_step_header "Sunshine server not available when container is run in 'secondary' mode"
    sed -i 's|^autostart.*=.*$|autostart=false|' /etc/supervisor.d/sunshine.ini
fi

echo -e "\e[34mDONE\e[0m"
