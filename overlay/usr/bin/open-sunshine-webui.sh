#!/usr/bin/env bash

set -euo pipefail

sunshine_config="${XDG_CONFIG_HOME:-${HOME:?}/.config}/sunshine/sunshine.conf"
sunshine_port=47989

if [[ -f "${sunshine_config}" ]]; then
    configured_port="$(sed -nE \
        's/^[[:space:]]*port[[:space:]]*=[[:space:]]*([0-9]+)[[:space:]]*$/\1/p' \
        "${sunshine_config}" | tail -n1)"
    if [[ "${configured_port}" =~ ^[0-9]+$ ]] &&
            (( configured_port >= 1 && configured_port < 65535 )); then
        sunshine_port="${configured_port}"
    fi
fi

sunshine_web_url="https://localhost:$((sunshine_port + 1))"

if command -v exo-open >/dev/null 2>&1; then
    exec exo-open --launch WebBrowser "${sunshine_web_url}"
fi

exec xdg-open "${sunshine_web_url}"
