#!/usr/bin/env bash
###
# File: start-dumb-udev.sh
# Project: bin
# File Created: Tuesday, 12th January 2022 8:46:47 am
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Friday, 14th January 2022 9:21:00 am
# Modified By: Josh.5 (jsunnex@gmail.com)
###
set -e

state_dir=/run/udev-input-fix

# CATCH TERM SIGNAL:
_term() {
    if [[ -n "${sync_pid:-}" ]]; then
        kill -TERM "${sync_pid}" 2>/dev/null || true
    fi
    if [[ -n "${dumb_udev_pid:-}" ]]; then
        kill -TERM "${dumb_udev_pid}" 2>/dev/null || true
    fi
}
trap _term SIGTERM SIGINT


sync_input_nodes() {
    sunshine_input_nodes_created=0
    mkdir -p /dev/input 2>/dev/null || return 0

    for sys_dev in /sys/class/input/*/dev; do
        [[ -f "${sys_dev}" ]] || continue

        input_name="$(basename "$(dirname "${sys_dev}")")"
        input_path="/dev/input/${input_name}"
        [[ -e "${input_path}" ]] && continue

        IFS=: read -r input_major input_minor < "${sys_dev}"
        if mknod "${input_path}" c "${input_major}" "${input_minor}" 2>/dev/null; then
            chmod 0660 "${input_path}" 2>/dev/null || true
            chgrp input "${input_path}" 2>/dev/null || true
            echo "Created missing input node '${input_path}'"

            input_device_name_file="/sys/class/input/${input_name}/device/name"
            if [[ -f "${input_device_name_file}" ]]; then
                case "$(cat "${input_device_name_file}" 2>/dev/null || true)" in
                    *passthrough*|Sunshine*)
                        sunshine_input_nodes_created=1
                        ;;
                esac
            fi
        fi
    done
}

sunshine_inputs_present() {
    for name_file in /sys/class/input/*/device/name; do
        [[ -f "${name_file}" ]] || continue
        case "$(cat "${name_file}" 2>/dev/null || true)" in
            *passthrough*|Sunshine*)
                return 0
                ;;
        esac
    done
    return 1
}


# EXECUTE PROCESS:
# Start dumb-udev
mkdir -p "${state_dir}"
dumb-udev &
dumb_udev_pid=$!

# A restricted container can expose an input device in sysfs without creating
# the matching node in its private /dev. Materialize only those missing nodes.
# In the normal host-network configuration udev creates the nodes and Xorg
# receives the hotplug event, so this loop leaves the working path untouched.
while kill -0 "${dumb_udev_pid}" 2>/dev/null; do
    sync_input_nodes

    if sunshine_inputs_present; then
        if (( sunshine_input_nodes_created )) &&
                [[ ! -e "${state_dir}/xorg-restarted" ]]; then
            # Sunshine creates its virtual devices after a client connects. If
            # this fallback had to create their device nodes, Xorg could not
            # have received the corresponding udev hotplug event. Restart it
            # once so the newly available devices are enumerated.
            sleep 2
            sync_input_nodes
            if supervisorctl restart xorg >/dev/null 2>&1; then
                : > "${state_dir}/xorg-restarted"
                echo "Restarted Xorg after materializing Sunshine input devices"
            else
                echo "WARNING: Could not restart Xorg after creating Sunshine input devices" >&2
            fi
        fi
    else
        rm -f "${state_dir}/xorg-restarted"
    fi

    sleep 1
done &
sync_pid=$!

# WAIT FOR CHILD PROCESS:
wait "$dumb_udev_pid"
