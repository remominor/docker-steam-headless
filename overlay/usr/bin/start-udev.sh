#!/usr/bin/env bash
###
# File: start-udev.sh
# Project: bin
# File Created: Tuesday, 12th January 2022 8:46:47 am
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Friday, 14th January 2022 9:21:00 am
# Modified By: Josh.5 (jsunnex@gmail.com)
###
set -e

# CATCH TERM SIGNAL:
_term() {
    if [[ -n "${udev_pid:-}" ]]; then
        kill -TERM "${udev_pid}" 2>/dev/null || true
    fi
}
trap _term SIGTERM SIGINT

# EXECUTE PROCESS:
# Start udev in the foreground so Supervisor owns its lifetime. The old
# --daemon plus `udevadm monitor` wrapper could leave an orphaned udevd behind
# after a service restart.
if command -v udevd &>/dev/null; then
    udev_command=(udevd)
else
    udev_command=(/lib/systemd/systemd-udevd)
fi
unshare --net "${udev_command[@]}" &
udev_pid=$!

# Wait for the daemon control socket instead of relying on a fixed delay, then
# request the initial device events. Failure is nonfatal because Xorg can still
# start and report an actionable input warning.
for _ in $(seq 1 50); do
    [[ -S /run/udev/control ]] && break
    sleep 0.1
done
udevadm trigger 2>/dev/null || echo "WARNING: Unable to trigger initial udev events" >&2

# WAIT FOR CHILD PROCESS:
wait "$udev_pid"
