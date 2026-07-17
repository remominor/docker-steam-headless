#!/usr/bin/env bash

echo "**** Configuring Firefox ****"

if firefox_bin="$(command -v firefox-esr)"; then
    firefox_desktop="firefox-esr.desktop"
    firefox_icon="firefox-esr"
    firefox_name="Firefox ESR"
elif firefox_bin="$(command -v firefox)"; then
    firefox_desktop="firefox.desktop"
    firefox_icon="firefox"
    firefox_name="Firefox"
else
    echo "ERROR: Firefox is not installed" >&2
    return 1 2>/dev/null || exit 1
fi

custom_webbrowser="$(cat <<EOF
[Desktop Entry]
NoDisplay=true
Version=1.0
Encoding=UTF-8
Type=X-XFCE-Helper
X-XFCE-Category=WebBrowser
X-XFCE-CommandsWithParameter=${firefox_bin} "%s"
Icon=${firefox_icon}
Name=${firefox_name}
X-XFCE-Commands=${firefox_bin}
EOF
)"

helper_dir="${USER_HOME:?}/.local/share/xfce4/helpers"
helper_file="${helper_dir}/custom-WebBrowser.desktop"
mkdir -p "${helper_dir}"
printf '%s\n' "${custom_webbrowser}" > "${helper_file}"

# Firefox ESR's Debian desktop entry is installed with the package. Failure to
# set a user MIME preference must not prevent the desktop from starting.
for mime_type in text/html x-scheme-handler/http x-scheme-handler/https; do
    if ! gio mime "${mime_type}" "${firefox_desktop}"; then
        echo "WARNING: Could not set Firefox ESR as the default for ${mime_type}" >&2
    fi
done

echo "DONE"
