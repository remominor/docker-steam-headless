#!/usr/bin/env bash
###
# File: common-functions.sh
# Project: bin
# File Created: Tuesday, 6th October 2022 9:30:00 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Tuesday, 6th October 2022 9:30:00 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###

# Wait for X server to start
#   (Credit: https://gist.github.com/tullmann/476cc71169295d5c3fe6)
wait_for_x() {
    MAX=240 # About 120 seconds
    CT=0
    while ! xdpyinfo >/dev/null 2>&1; do
        sleep 0.50s
        CT=$(( CT + 1 ))
        if [ "$CT" -ge "$MAX" ]; then
            echo "FATAL: $0: Gave up waiting for X server $DISPLAY"
            exit 11
        fi
    done
}

# SDL normally uses RandR to enumerate X11 displays. NVIDIA can provide a
# usable headless framebuffer without exposing any connected RandR output;
# SDL applications then fail window creation with "Could not find display
# info". Fall back to the root X screen only for that headless case. Preserve
# an explicit user setting and normal RandR behavior whenever an output exists.
configure_sdl_x11_display_detection() {
    if [[ -n "${SDL_VIDEO_X11_XRANDR+x}" ]]; then
        return
    fi

    local xrandr_output
    xrandr_output="$(xrandr --query 2>/dev/null || true)"
    if ! grep -Eq '^[^[:space:]]+[[:space:]]+connected([[:space:]]|$)' <<<"${xrandr_output}"; then
        echo "  - X exposes no connected RandR output; disabling SDL XRandR discovery"
        export SDL_VIDEO_X11_XRANDR=0
    fi
}

# Wait for udev init to complete
wait_for_udev() {
    MAX=30
    CT=0
    while [ ! -e /run/udev/control ]; do
        sleep 1
        CT=$(( CT + 1 ))
        if [ "$CT" -ge "$MAX" ]; then
            echo "FATAL: $0: Gave up waiting for udev server to start"
            exit 11
        fi
    done
}

# Wait for dockerd to start
wait_for_docker() {
    MAX=10
    CT=0
    while ! docker system info >/dev/null 2>&1; do
        sleep 1
        CT=$(( CT + 1 ))
        if [ "$CT" -ge "$MAX" ]; then
            echo "FATAL: $0: Gave up waiting for dockerd service to start"
            exit 11
        fi
    done
    echo "DOCKERD RUNNING!"
}

# Wait for desktop to start
wait_for_desktop() {
    MAX=30
    CT=0
    while [ ! -f /tmp/.started-desktop ]; do
        sleep 1
        CT=$(( CT + 1 ))
        if [ "$CT" -ge "$MAX" ]; then
            echo "FATAL: $0: Gave up waiting for Desktop to start"
            exit 11
        fi
    done
}

# Fetch the NVIDIA GPU to use for Xorg and Sunshine. The Unraid NVIDIA runtime
# consumes NVIDIA_VISIBLE_DEVICES while preparing the container and can replace
# its in-process value with "void", even though the requested GPUs are exposed.
# Query the visible inventory instead of passing that environment value back to
# `nvidia-smi --id`.
get_nvidia_gpu_id() {
    local gpu_selector="${NVIDIA_PRIMARY_GPU:-${NVIDIA_VISIBLE_DEVICES:-all}}"
    local gpu_select=""
    local gpu_inventory=""

    if ! command -v nvidia-smi >/dev/null 2>&1; then
        return 1
    fi

    gpu_selector="${gpu_selector%%,*}"
    gpu_inventory="$(nvidia-smi \
        --query-gpu=index,uuid \
        --format=csv,noheader,nounits 2>/dev/null || true)"

    if [[ "${gpu_selector}" =~ ^GPU-[[:xdigit:]-]+$ ]]; then
        gpu_select="$(awk -F',' -v wanted="${gpu_selector}" '
            {
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
                if ($2 == wanted) { print $2; exit }
            }
        ' <<<"${gpu_inventory}")"
    elif [[ "${gpu_selector}" =~ ^[0-9]+$ ]]; then
        gpu_select="$(awk -F',' -v wanted="${gpu_selector}" '
            {
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
                if ($1 == wanted) { print $2; exit }
            }
        ' <<<"${gpu_inventory}")"
    elif [[ -z "${gpu_selector}" ||
            "${gpu_selector}" == "all" ||
            "${gpu_selector}" == "void" ]]; then
        gpu_select="$(awk -F',' '
            {
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
                if ($2 ~ /^GPU-[[:xdigit:]-]+$/) { print $2; exit }
            }
        ' <<<"${gpu_inventory}")"
    else
        return 1
    fi

    # Some NVIDIA/Unraid runtime failures print diagnostics such as
    # "No devices were found" on stdout. Never let that text become a GPU ID
    # or, later, an Xorg PCI BusID.
    if [[ ! "${gpu_select}" =~ ^GPU-[[:xdigit:]-]+$ ]]; then
        return 1
    fi

    echo "${gpu_select}"
}

# Query one property without `nvidia-smi --id`, which is unreliable after the
# Unraid runtime has consumed NVIDIA_VISIBLE_DEVICES.
get_nvidia_gpu_property() {
    local gpu_uuid="${1:?GPU UUID required}"
    local property="${2:?GPU property required}"
    local value=""

    if [[ ! "${property}" =~ ^(name|pci[.]bus_id|driver_version)$ ]]; then
        return 1
    fi

    value="$(nvidia-smi \
        --query-gpu="uuid,${property}" \
        --format=csv,noheader,nounits 2>/dev/null |
        awk -F',' -v wanted="${gpu_uuid}" '
            {
                uuid = $1
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", uuid)
                if (uuid == wanted) {
                    sub(/^[^,]*,[[:space:]]*/, "", $0)
                    sub(/[[:space:]]+$/, "", $0)
                    print $0
                    exit
                }
            }
        ' || true)"

    [[ -n "${value}" ]] || return 1
    echo "${value}"
}

export_desktop_dbus_session() {
    local session_file="/tmp/.dbus-desktop-session.env"
    local session_file_tmp

    if [[ -f "${session_file}" ]]; then
        set -a
        # The file is generated locally with shell-escaped values.
        source "${session_file}"
        set +a
        return
    fi

    eval "$(dbus-launch --sh-syntax)"
    export DBUS_SESSION_BUS_ADDRESS DBUS_SESSION_BUS_PID

    session_file_tmp="$(mktemp /tmp/.dbus-desktop-session.env.XXXXXX)"
    {
        printf 'DBUS_SESSION_BUS_ADDRESS=%q\n' "${DBUS_SESSION_BUS_ADDRESS:?}"
        printf 'DBUS_SESSION_BUS_PID=%q\n' "${DBUS_SESSION_BUS_PID:?}"
    } >"${session_file_tmp}"
    chmod 0600 "${session_file_tmp}"
    mv -f "${session_file_tmp}" "${session_file}"
}

# Wait for desktop dbus session to start
wait_for_desktop_dbus_session() {
    MAX=10
    CT=0
    while [ ! -f /tmp/.dbus-desktop-session.env ]; do
        sleep 1
        CT=$(( CT + 1 ))
        if [ "$CT" -ge "$MAX" ]; then
            echo "FATAL: $0: Gave up waiting for Desktop dbus-launch session to be created"
            exit 11
        fi
    done
}
