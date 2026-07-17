#!/usr/bin/env bash
###
# File: start-desktop.sh
# Project: bin
# File Created: Thursday, 1st January 1970 12:00:00 pm
# Author: Console and webGui login account (jsunnex@gmail.com)
# -----
# Last Modified: Saturday, 8th July 2023 6:16:47 pm
# Modified By: Console and webGui login account (jsunnex@gmail.com)
###
set -e
source /usr/bin/common-functions.sh

# CATCH TERM SIGNAL:
_term() {
    if [[ -n "${optional_apps_pid:-}" ]]; then
        kill -TERM "${optional_apps_pid}" 2>/dev/null || true
    fi
    if [[ -n "${desktop_pid:-}" ]]; then
        kill -TERM "${desktop_pid}" 2>/dev/null || true
    fi
}
trap _term SIGTERM SIGINT

cleanup_session() {
    rm -f /tmp/.started-desktop /tmp/.dbus-desktop-session.env
    if [[ -n "${DBUS_SESSION_BUS_PID:-}" ]]; then
        kill -TERM "${DBUS_SESSION_BUS_PID}" 2>/dev/null || true
    fi
}
trap cleanup_session EXIT


# CONFIGURE:
# Remove lockfile
rm -f /tmp/.started-desktop
# Remove the previous session environment before waiting for a fresh X server.
rm -fv /tmp/.dbus-desktop-session.env
# Configure some XDG environment variables
export XDG_CACHE_HOME="${USER_HOME:?}/.cache"
export XDG_CONFIG_HOME="${USER_HOME:?}/.config"
export XDG_DATA_HOME="${USER_HOME:?}/.local/share"

# EXECUTE PROCESS:
# Wait for the X server to start
wait_for_x
configure_sdl_x11_display_detection
# Start one session bus shared by XFCE and Sunshine only after X is ready.
export_desktop_dbus_session
# Wait for the X server to start using a robust, self-contained loop.
# echo "--> Waiting for X server on display ${DISPLAY}..."
# while ! xset -q >/dev/null 2>&1; do
#   sleep 1
# done
# echo "--> X server is ready."

# Firefox itself is installed in the image from Debian's repositories. This
# only sets the per-user XFCE and MIME defaults and performs no network access.
source /usr/bin/configure_firefox.sh

# Run the desktop environment
echo "**** Starting Xfce4 ****"
# export_desktop_dbus_session already created the session bus that Sunshine
# imports. Starting a second bus with dbus-run-session left Sunshine and XFCE
# on different buses and caused tray/service activation failures.
/usr/bin/startxfce4 &
desktop_pid=$!
touch /tmp/.started-desktop

# ProtonUp-Qt is useful but not required for the desktop or Sunshine. Install
# it after starting XFCE so a slow or unavailable Flathub cannot block either.
optional_apps_pid=""
if [[ ! -f /tmp/.desktop-apps-updated ]]; then
    (
        if /usr/bin/install_protonup.sh >>"${USER_HOME:?}/.cache/log/protonup-install.log" 2>&1; then
            touch /tmp/.desktop-apps-updated
        else
            echo "WARNING: Optional desktop app update failed; it will be retried on restart" >&2
        fi
    ) &
    optional_apps_pid=$!
fi

# WAIT FOR CHILD PROCESS:
desktop_status=0
wait "$desktop_pid" || desktop_status=$?

if [[ -n "${optional_apps_pid:-}" ]]; then
    kill -TERM "${optional_apps_pid}" 2>/dev/null || true
fi
exit "${desktop_status}"
