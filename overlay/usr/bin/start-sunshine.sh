#!/usr/bin/env bash
###
# File: start-sunshine.sh
# Project: bin
# File Created: Tuesday, 4th October 2022 8:22:17 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Wednesday, 27th November 2024 3:54:19 pm
# Modified By: Josh5 (jsunnex@gmail.com)
###
set -e
source /usr/bin/common-functions.sh

# CATCH TERM SIGNAL:
_term() {
    if [[ -z "${sunshine_pid:-}" ]]; then
        exit 0
    fi

    kill -INT "$sunshine_pid" 2>/dev/null || true
    sleep 0.5
    counter=0
    while kill -0 "$sunshine_pid" 2>/dev/null; do
        kill -TERM "$sunshine_pid" 2>/dev/null || true
        counter=$((counter + 1))
        [ "$counter" -gt 8 ] && break
        sleep 0.5
    done
    counter=0
    while kill -0 "$sunshine_pid" 2>/dev/null; do
        kill -KILL "$sunshine_pid" 2>/dev/null || true
        counter=$((counter + 1))
        [ "$counter" -gt 4 ] && break
        sleep 0.5
    done
    exit 0
}
trap _term SIGTERM SIGINT


# CONFIGURE:
# Install default configurations
mkdir -p "${USER_HOME:?}/.config/sunshine"
if [ ! -f "${USER_HOME:?}/.config/sunshine/sunshine.conf" ]; then
    cp -vf /templates/sunshine/sunshine.conf "${USER_HOME:?}/.config/sunshine/sunshine.conf"
fi
# `channels` was accepted by older Sunshine releases but is no longer a
# configurable option. Remove it from persistent configurations so upgrades do
# not emit a warning on every start.
sed -i -E '/^[[:space:]]*channels[[:space:]]*=/d' \
    "${USER_HOME:?}/.config/sunshine/sunshine.conf"

# Sunshine 2026.516 added CSRF protection. Preserve an origin explicitly set
# by the user. For a clean host-networked container, seed private interface IPs
# so the Web UI can save settings when opened from another LAN machine.
sunshine_config="${USER_HOME:?}/.config/sunshine/sunshine.conf"
if [[ -n "${SUNSHINE_CSRF_ALLOWED_ORIGINS:-}" ]]; then
    sed -i -E '/^[[:space:]]*csrf_allowed_origins[[:space:]]*=/d' \
        "${sunshine_config}"
    printf '\ncsrf_allowed_origins = %s\n' \
        "${SUNSHINE_CSRF_ALLOWED_ORIGINS}" >>"${sunshine_config}"
elif ! grep -Eq '^[[:space:]]*csrf_allowed_origins[[:space:]]*=' \
        "${sunshine_config}"; then
    csrf_origins=()
    for host_ip in $(hostname -I 2>/dev/null || true); do
        if [[ "${host_ip}" =~ ^10\. ||
                "${host_ip}" =~ ^192\.168\. ||
                "${host_ip}" =~ ^172\.(1[6-9]|2[0-9]|3[01])\. ]]; then
            csrf_origins+=("https://${host_ip}")
        fi
    done
    if (( ${#csrf_origins[@]} > 0 )); then
        csrf_origins_csv="$(IFS=,; echo "${csrf_origins[*]}")"
        printf '\ncsrf_allowed_origins = %s\n' \
            "${csrf_origins_csv}" >>"${sunshine_config}"
    fi
fi

# On NVIDIA, fail visibly if NVENC cannot initialize instead of silently
# falling back to CPU encoding. Preserve any encoder selected by the user.
if command -v nvidia-smi >/dev/null 2>&1 &&
        ! grep -Eq '^[[:space:]]*encoder[[:space:]]*=' "${sunshine_config}"; then
    printf '\nencoder = nvenc\n' >>"${sunshine_config}"
fi
if [ ! -f "${USER_HOME:?}/.config/sunshine/apps.json" ]; then
    cp -vf /templates/sunshine/apps.json "${USER_HOME:?}/.config/sunshine/apps.json"
fi
if [ ! -f "${USER_HOME:?}/.config/sunshine/sunshine_state.json" ]; then
    echo "{}" > "${USER_HOME:?}/.config/sunshine/sunshine_state.json"
fi
# Reset the default username/password
if ([ "X${SUNSHINE_USER:-}" != "X" ] && [ "X${SUNSHINE_PASS:-}" != "X" ]); then
    /usr/bin/sunshine "${USER_HOME:?}/.config/sunshine/sunshine.conf" --creds "${SUNSHINE_USER:?}" "${SUNSHINE_PASS:?}"
fi
# If we are running the SHUI, then force the same user upon sunshine
if ([ "X${WEBUI_USER:-}" != "X" ] && [ "X${WEBUI_PASS:-}" != "X" ]); then
    /usr/bin/sunshine "${USER_HOME:?}/.config/sunshine/sunshine.conf" --creds "${WEBUI_USER:?}" "${WEBUI_PASS:?}"
fi
# Remove any auto-start scripts from user's .local dir
if [ -f "${USER_HOME:?}/.config/autostart/Sunshine.desktop" ]; then
    rm -fv "${USER_HOME:?}/.config/autostart/Sunshine.desktop"
fi


# EXECUTE PROCESS:
# Wait for the X server to start
wait_for_x

# Sunshine depends on files published by start-desktop.sh. Waiting here keeps
# the Supervisor program stable if XFCE is slow or temporarily unavailable;
# the previous short timeouts caused an endless exit-11 restart loop.
echo "Waiting for the desktop D-Bus session and XFCE startup marker"
while [[ ! -f /tmp/.dbus-desktop-session.env || ! -f /tmp/.started-desktop ]]; do
    sleep 1
done
export_desktop_dbus_session

# Sunshine injects Linux keyboard, mouse, and controller events through uinput.
# Keep video streaming available when the host did not pass the device, but
# make the loss of remote input explicit in the service log.
if [[ ! -c /dev/uinput ]]; then
    echo "WARNING: /dev/uinput is unavailable; Sunshine remote input will not work" >&2
elif [[ ! -r /dev/uinput || ! -w /dev/uinput ]]; then
    echo "WARNING: User '$(id -un)' cannot read and write /dev/uinput; Sunshine remote input will not work" >&2
fi

# A root framebuffer without a connected RandR output is sufficient for VNC,
# but Sunshine's X11 capture either fails or returns black frames. Do not launch
# the server until Xorg publishes the synthetic/physical output.
echo "Waiting for a connected RandR output"
while ! xrandr --query 2>/dev/null | grep -Eq '^[^[:space:]]+[[:space:]]+connected([[:space:]]|$)'; do
    sleep 1
done

# Start the sunshine server
/usr/bin/dumb-init /usr/bin/sunshine "${USER_HOME:?}/.config/sunshine/sunshine.conf" &
sunshine_pid=$!


# WAIT FOR CHILD PROCESS:
wait "$sunshine_pid"
