#!/usr/bin/env bash

set -e
source /usr/bin/common-functions.sh

wait_for_x
configure_sdl_x11_display_detection

if [[ -x /usr/games/steam ]]; then
    exec /usr/games/steam "$@"
fi

exec /usr/bin/steam "$@"
