#!/usr/bin/env bash
###
# File: start-x11vnc.sh
# Project: bin
# File Created: Tuesday, 6th October 2022 9:30:00 pm
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Tuesday, 6th October 2022 9:30:00 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###
set -e
source /usr/bin/common-functions.sh

# EXECUTE PROCESS:
# Wait for the X server to start
wait_for_x
# Start the x11vnc server
exec /usr/bin/x11vnc \
    -display "${DISPLAY:?}" \
    -rfbport "${PORT_VNC:?}" \
    -shared \
    -forever
