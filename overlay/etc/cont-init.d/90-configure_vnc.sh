
print_header "Configure VNC"

function get_next_unused_port() {
    local __start_port=$(( ${1:?} + 1 ))
    local __used_ports
    local __check_port

    __used_ports="$(netstat -lntu 2>/dev/null | awk 'NR > 2 {
        address = $4
        sub(/^.*:/, "", address)
        if (address ~ /^[0-9]+$/) print address
    }' | sort -u)"

    for __check_port in $(seq "${__start_port}" 65000); do
        if ! grep -Fxq "${__check_port}" <<<"${__used_ports}"; then
            echo "${__check_port}"
            return 0
        fi
    done
    print_error "No unused TCP/UDP port found after ${__start_port}"
    return 1
}

# Configure random ports for VNC service, pulseaudio socket, noVNC service and audio transport websocket
# Note: Ports 32035-32248 are unallocated port ranges. We should be able to find something in here that we can use
#   REF: https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml?&page=130
DYNAMIC_PORT_VNC=$(get_next_unused_port 32035)
export PORT_VNC=${PORT_VNC:-$DYNAMIC_PORT_VNC}
print_step_header "Configure VNC service port '${PORT_VNC}'"
DYNAMIC_PORT_AUDIO_STREAM=$(get_next_unused_port ${DYNAMIC_PORT_VNC})
export PORT_AUDIO_STREAM=${PORT_AUDIO_STREAM:-$DYNAMIC_PORT_AUDIO_STREAM}
print_step_header "Configure pulseaudio encoded stream port '${PORT_AUDIO_STREAM}'"

if ([ "${MODE}" != "s" ] && [ "${MODE}" != "secondary" ]); then

    if [ "${WEB_UI_MODE:-}" = "vnc" ]; then
        print_step_header "Enable VNC server"
        sed -i 's|^autostart.*=.*$|autostart=true|' /etc/supervisor.d/vnc.ini

        # TODO: Remove this... Always enable VNC audio
        if [[ "${ENABLE_VNC_AUDIO}" == "true" ]]; then
            # Enable supervisord script
            sed -i 's|^autostart.*=.*$|autostart=true|' /etc/supervisor.d/vnc-audio.ini
        else
            print_step_header "Disable audio stream"
            print_step_header "Disable audio websock"
            # Disable supervisord script
            sed -i 's|^autostart.*=.*$|autostart=false|' /etc/supervisor.d/vnc-audio.ini
        fi
    else
        print_step_header "Disable VNC server"
        sed -i 's|^autostart.*=.*$|autostart=false|' /etc/supervisor.d/vnc.ini
        sed -i 's|^autostart.*=.*$|autostart=false|' /etc/supervisor.d/vnc-audio.ini
    fi
else
    print_step_header "VNC server not available when container is run in 'secondary' mode"
    sed -i 's|^autostart.*=.*$|autostart=false|' /etc/supervisor.d/vnc.ini
    sed -i 's|^autostart.*=.*$|autostart=false|' /etc/supervisor.d/vnc-audio.ini
fi

echo -e "\e[34mDONE\e[0m"
