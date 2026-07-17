# Select the primary NVIDIA GPU from the runtime-visible inventory. Unraid can
# replace NVIDIA_VISIBLE_DEVICES with "void" after exposing the requested GPUs;
# NVIDIA_PRIMARY_GPU provides an optional stable selector for multi-GPU hosts.
source /usr/bin/common-functions.sh

gpu_select="$(get_nvidia_gpu_id 2>/dev/null || true)"
export gpu_select

nvidia_gpu_hex_id=""
if [[ -n "${gpu_select}" ]]; then
    nvidia_gpu_hex_id="$(get_nvidia_gpu_property "${gpu_select}" pci.bus_id 2>/dev/null || true)"
fi
export nvidia_gpu_hex_id

monitor_connected="$(awk '/^connected$/ { print; exit }' /sys/class/drm/card*/status 2>/dev/null || true)"
export monitor_connected

# Reuse a display size selected in XFCE when the persisted configuration is
# complete and valid. Otherwise retain the container environment defaults.
displays_file="${USER_HOME}/.config/xfce4/xfconf/xfce-perchannel-xml/displays.xml"
if [[ -f "${displays_file}" ]]; then
    new_display_resolution="$(grep -m1 'Resolution' "${displays_file}" | sed -n 's/.*value="\([^"]*\)".*/\1/p')"
    new_display_refresh="$(grep -m1 'RefreshRate' "${displays_file}" | sed -n 's/.*value="\([^"]*\)".*/\1/p')"

    if [[ "${new_display_resolution}" =~ ^([0-9]+)x([0-9]+)$ ]]; then
        new_display_sizew="${BASH_REMATCH[1]}"
        new_display_sizeh="${BASH_REMATCH[2]}"
    else
        new_display_sizew=""
        new_display_sizeh=""
    fi

    if [[ -n "${new_display_sizew}" &&
            "${new_display_refresh}" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        export DISPLAY_SIZEW="${new_display_sizew}"
        export DISPLAY_SIZEH="${new_display_sizeh}"
        # Round the persisted rate to the closest positive multiple of 60.
        export DISPLAY_REFRESH="$(awk -v rate="${new_display_refresh}" 'BEGIN {
            rounded = int((rate + 30) / 60) * 60
            if (rounded < 30) rounded += 60
            print rounded
        }')"
    else
        print_warning "Ignoring incomplete or invalid XFCE display configuration in '${displays_file}'"
    fi
fi

# Configure a deterministic NVIDIA-backed synthetic X11 display. This avoids
# nvidia-xconfig hardware probing, which is unreliable inside a container, and
# ensures RandR exposes an output that Steam and Sunshine can use.
configure_nvidia_x_server() {
    local pci_domain
    local pci_bus
    local pci_device
    local pci_function
    local bus_id
    local display_output="${DISPLAY_VIDEO_PORT:-DP-0}"
    local modeline
    local mode_name
    local mode_debug_option=""
    local xorg_config_tmp

    print_step_header "Configuring synthetic X11 display with GPU ID: '${gpu_select}'"

    if [[ ! "${nvidia_gpu_hex_id}" =~ ^[[:xdigit:]]+:[[:xdigit:]]+:[[:xdigit:]]+[.][[:xdigit:]]+$ ]]; then
        print_error "Invalid NVIDIA PCI bus ID '${nvidia_gpu_hex_id}'"
        return 1
    fi
    IFS=':.' read -r pci_domain pci_bus pci_device pci_function <<<"${nvidia_gpu_hex_id}"
    bus_id="PCI:$((16#${pci_bus})):$((16#${pci_device})):$((16#${pci_function}))"

    if [[ ! "${DISPLAY_SIZEW:-}" =~ ^[0-9]+$ ||
            ! "${DISPLAY_SIZEH:-}" =~ ^[0-9]+$ ||
            ! "${DISPLAY_REFRESH:-}" =~ ^[0-9]+$ ||
            ! "${DISPLAY_CDEPTH:-}" =~ ^[0-9]+$ ]]; then
        print_error "Invalid display geometry '${DISPLAY_SIZEW:-}x${DISPLAY_SIZEH:-}@${DISPLAY_REFRESH:-}' depth '${DISPLAY_CDEPTH:-}'"
        return 1
    fi

    # These are NVIDIA RandR output names. A concrete output is required;
    # generic values such as DFP can leave the server in MetaMode NULL.
    if [[ ! "${display_output}" =~ ^(DP|HDMI|DFP|DVI-D|DVI-I)-[0-9]+$ ]]; then
        print_error "Invalid DISPLAY_VIDEO_PORT '${display_output}'. Use a concrete output such as DP-0."
        return 1
    fi

    modeline="$(cvt -r "${DISPLAY_SIZEW}" "${DISPLAY_SIZEH}" "${DISPLAY_REFRESH}" 2>/dev/null | sed -n '2p')"
    if [[ -z "${modeline}" ]]; then
        print_error "Unable to generate a modeline for ${DISPLAY_SIZEW}x${DISPLAY_SIZEH}@${DISPLAY_REFRESH}"
        return 1
    fi
    mode_name="$(awk '{ print $2 }' <<<"${modeline}" | tr -d '"')"

    if [[ "${XORG_MODE_DEBUG:-false}" == "true" ]]; then
        mode_debug_option='    Option "ModeDebug" "True"'
    fi

    print_step_header "Configuring X11 with PCI bus ID: '${bus_id}'"
    print_step_header "Creating synthetic output '${display_output}' with ${modeline}"

    xorg_config_tmp="$(mktemp /etc/X11/xorg.conf.XXXXXX)"
    cat >"${xorg_config_tmp}" <<EOF
Section "Files"
    # The NVIDIA container runtime installs host-matched Xorg modules here.
    # Debian's remaining Xorg modules continue to come from /usr/lib.
    ModulePath "/usr/lib64/xorg/modules"
    ModulePath "/usr/lib/xorg/modules"
EndSection

Section "ServerLayout"
    Identifier "HeadlessLayout"
    Screen 0 "HeadlessScreen" 0 0
EndSection

Section "Monitor"
    Identifier "HeadlessMonitor"
    ${modeline}
    HorizSync 5.0 - 1000.0
    VertRefresh 5.0 - 240.0
    Option "Enable" "True"
EndSection

Section "Device"
    Identifier "NvidiaGPU"
    Driver "nvidia"
    BusID "${bus_id}"
    Option "AllowEmptyInitialConfiguration" "True"
    Option "AllowExternalGpus" "True"
    Option "ConnectedMonitor" "${display_output}"
    Option "MetaModes" "${display_output}: ${mode_name} +0+0"
    Option "ModeValidation" "NoDFPNativeResolutionCheck, NoVirtualSizeCheck, NoMaxPClkCheck, NoEdidMaxPClkCheck, NoMaxSizeCheck, NoHorizSyncCheck, NoVertRefreshCheck, NoWidthAlignmentCheck, NoTotalSizeCheck, NoDualLinkDVICheck, NoDisplayPortBandwidthCheck, AllowNon3DVisionModes, AllowNonHDMI3DModes, AllowNonEdidModes, NoEdidHDMI2Check, AllowDpInterlaced"
${mode_debug_option}
EndSection

Section "Screen"
    Identifier "HeadlessScreen"
    Device "NvidiaGPU"
    Monitor "HeadlessMonitor"
    DefaultDepth ${DISPLAY_CDEPTH}
    Option "TwinView" "True"
    Option "ProbeAllGpus" "False"
    Option "BaseMosaic" "False"
    SubSection "Display"
        Depth ${DISPLAY_CDEPTH}
        Virtual ${DISPLAY_SIZEW} ${DISPLAY_SIZEH}
        Modes "${mode_name}"
    EndSubSection
EndSection

Section "ServerFlags"
    Option "AutoAddGPU" "False"
EndSection
EOF
    chmod 0644 "${xorg_config_tmp}"
    mv -f "${xorg_config_tmp}" /etc/X11/xorg.conf
}

# Configure Xorg service selection and runtime directories.
configure_x_server() {
    if [[ ! -f /etc/X11/Xwrapper.config ]]; then
        print_step_header "Create Xwrapper.config"
        printf 'allowed_users=anybody\nneeds_root_rights=yes\n' >/etc/X11/Xwrapper.config
    else
        sed -i 's/^allowed_users=console$/allowed_users=anybody/' /etc/X11/Xwrapper.config
        grep -Fqx 'allowed_users=anybody' /etc/X11/Xwrapper.config || echo 'allowed_users=anybody' >>/etc/X11/Xwrapper.config
        grep -Fqx 'needs_root_rights=yes' /etc/X11/Xwrapper.config || echo 'needs_root_rights=yes' >>/etc/X11/Xwrapper.config
    fi

    rm -f /etc/X11/xorg.conf
    mkdir -p "${XORG_SOCKET_DIR:?}"

    display_file="${XORG_SOCKET_DIR}/X${DISPLAY#:}"
    display_lock="/tmp/.X${DISPLAY#:}-lock"
    if [[ -S "${display_file}" || -e "${display_lock}" ]]; then
        print_step_header "Removing stale X display files for '${DISPLAY}'"
        rm -f "${display_lock}" "${display_file}"
    fi

    mkdir -p /tmp/.ICE-unix
    chown root:root /tmp/.ICE-unix
    chmod 1777 /tmp/.ICE-unix

    if [[ "${MODE}" == "p" || "${MODE}" == "primary" ]]; then
        print_step_header "Configure container as primary X server"
        sed -i 's|^autostart.*=.*$|autostart=true|' /etc/supervisor.d/xorg.ini
        sed -i 's|^autostart.*=.*$|autostart=false|' /etc/supervisor.d/xvfb.ini
    elif [[ "${MODE}" == "fb" || "${MODE}" == "framebuffer" ]]; then
        print_step_header "Configure container to use Xvfb"
        sed -i 's|^autostart.*=.*$|autostart=false|' /etc/supervisor.d/xorg.ini
        sed -i 's|^autostart.*=.*$|autostart=true|' /etc/supervisor.d/xvfb.ini
    else
        print_step_header "Configure container with no local X server"
        sed -i 's|^autostart.*=.*$|autostart=false|' /etc/supervisor.d/xorg.ini
        sed -i 's|^autostart.*=.*$|autostart=false|' /etc/supervisor.d/xvfb.ini
    fi

    if [[ "${ENABLE_EVDEV_INPUTS:-false}" == "true" ]]; then
        print_step_header "Enabling evdev input classes"
        cp -f /usr/share/X11/xorg.conf.d/10-evdev.conf /etc/X11/xorg.conf.d/10-evdev.conf
    else
        print_step_header "Leaving evdev inputs disabled"
        rm -f /etc/X11/xorg.conf.d/10-evdev.conf
    fi

    if [[ "${FORCE_X11_DUMMY_CONFIG:-false}" == "true" ||
            ( -z "${nvidia_gpu_hex_id}" && -z "${monitor_connected}" ) ]]; then
        print_step_header "No monitor detected; installing default dummy Xorg configuration"
        cp -f /templates/xorg/xorg.dummy.conf /etc/X11/xorg.conf
    fi
}

if [[ "${MODE}" != "s" && "${MODE}" != "secondary" ]]; then
    configure_x_server

    if [[ "${MODE}" == "p" || "${MODE}" == "primary" ]]; then
        if [[ -n "${nvidia_gpu_hex_id}" && "${FORCE_X11_DUMMY_CONFIG:-false}" != "true" ]]; then
            print_header "Generate NVIDIA synthetic-display xorg.conf"
            if ! configure_nvidia_x_server; then
                print_error "Unable to generate NVIDIA synthetic-display xorg.conf"
                exit 1
            fi
        else
            print_header "Use default Xorg configuration"
        fi
    fi
fi

echo -e "\e[34mDONE\e[0m"
