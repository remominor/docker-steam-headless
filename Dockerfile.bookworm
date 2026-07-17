FROM debian:bookworm-slim
LABEL maintainer="Josh.5 <jsunnex@gmail.com>"

# Update package repos
ARG DEBIAN_FRONTEND=noninteractive
RUN \
    echo "**** Update apt database ****" \
        && sed -i '/^Components: main/ s/$/ contrib non-free/' /etc/apt/sources.list.d/debian.sources \
    && \
    echo

# Enable i386 architecture for 32-bit libraries
RUN dpkg --add-architecture i386

# Update locale
RUN \
    echo "**** Update apt database ****" \
        && apt-get update \
    && \
    echo "**** Install and configure locals ****" \
        && apt-get install -y --no-install-recommends \
            locales \
        && echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen \
        && locale-gen \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/* \
    && \
    echo
ENV \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# Re-install certificates
RUN \
    echo "**** Update apt database ****" \
        && apt-get update \
    && \
    echo "**** Install certificates ****" \
        && apt-get install -y --reinstall \
            ca-certificates \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/* \
    && \
    echo

# Install core packages
RUN \
    echo "**** Update apt database ****" \
        && apt-get update \
    && \
    echo "**** Install tools ****" \
        && apt-get install -y --no-install-recommends \
            bash \
            bash-completion \
            curl \
            git \
            jq \
            less \
            man-db \
            plocate \
            nano \
            net-tools \
            p7zip-full \
            patch \
            pciutils \
            pkg-config \
            procps \
            psmisc \
            psutils \
            rsync \
            screen \
            sudo \
            unzip \
            vim \
            wget \
            xmlstarlet \
            xz-utils \
    && \
    echo "**** Install python ****" \
        && apt-get install -y --no-install-recommends \
            python3 \
            python3-numpy \
            python3-pip \
            python3-setuptools \
            python3-venv \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/* \
    && \
    echo


# START: JC141 Compatibility Additions
# ------------------------------------------------------------------------------
# Install dependencies required by jc141 images
RUN \
    echo "**** Installing jc141 dependencies ****" \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        fuse3 \
        fuse-overlayfs \
        bubblewrap \
        pipewire \
        pipewire:i386 \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf /var/lib/apt/lists/*

# Install Wine-Staging from WineHQ
RUN \
    echo "**** Installing WineHQ ****" \
    && apt-get update \
    && apt-get install -y --no-install-recommends software-properties-common gnupg wget \
    && mkdir -p /etc/apt/keyrings \
    && wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key \
    && wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources \
    && apt-get update \
    && apt-get install -y --install-recommends winehq-staging winetricks \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf /var/lib/apt/lists/*

# Install pinned pre-built DwarFS binaries instead of compiling from source
ARG DWARFS_VERSION=0.15.5
ARG DWARFS_SHA256=2444fbf7d1c4c0af5417d6c26ab3d0537f43da2fbc721ecce60eae6547ba991b
RUN \
    echo "**** Installing DwarFS v${DWARFS_VERSION} pre-built binaries ****" \
    && wget --no-verbose \
        "https://github.com/mhx/dwarfs/releases/download/v${DWARFS_VERSION}/dwarfs-${DWARFS_VERSION}-Linux-x86_64.tar.xz" \
        -O /tmp/dwarfs.tar.xz \
    && echo "${DWARFS_SHA256}  /tmp/dwarfs.tar.xz" | sha256sum -c - \
    && mkdir -p /tmp/dwarfs-bin \
    && tar -xJf /tmp/dwarfs.tar.xz -C /tmp/dwarfs-bin --strip-components=1 \
    && find /tmp/dwarfs-bin/bin /tmp/dwarfs-bin/sbin \
        -maxdepth 1 -type f -exec install -m 0755 -t /usr/local/bin/ {} + \
    && rm -rf /tmp/dwarfs.tar.xz /tmp/dwarfs-bin
# ------------------------------------------------------------------------------
# END: JC141 Compatibility Additions


# Configure default user and set user env
ENV \
    PUID=99 \
    PGID=100 \
    UMASK=000 \
    USER="default" \
    USER_PASSWORD="password" \
    USER_HOME="/home/default" \
    TZ="Pacific/Auckland" \
    USER_LOCALES="en_US.UTF-8 UTF-8"
# Xorg runs with access control disabled, but sandboxed launchers such as the
# JC141 scripts still expect XAUTHORITY to name an existing file before they
# bind it into an isolated home.
ENV XAUTHORITY="/home/default/.Xauthority"
RUN \
    echo "**** Configure default user '${USER}' ****" \
        && mkdir -p \
            ${USER_HOME} \
        && useradd -d ${USER_HOME} -s /bin/bash ${USER} \
        && chown -R ${USER} \
            ${USER_HOME} \
        && echo "${USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && \
    echo

# Install supervisor
RUN \
    echo "**** Update apt database ****" \
        && apt-get update \
    && \
    echo "**** Install supervisor ****" \
        && apt-get install -y \
            supervisor \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/* \
    && \
    echo

# Install X Server requirements
# TODO: Refine this list of packages to only what is required.
ENV \
    XORG_SOCKET_DIR="/tmp/.X11-unix" \
    XDG_RUNTIME_DIR="/tmp/.X11-unix/run" \
    XDG_SESSION_TYPE="x11" \
    FORCE_X11_DUMMY_CONFIG="false"
RUN \
    echo "**** Update apt database ****" \
        && apt-get update \
    && \
    echo "**** Install X Server requirements ****" \
        && apt-get install -y --no-install-recommends \
            avahi-utils \
            dbus-x11 \
            libxcomposite-dev \
            libxcursor1 \
            wmctrl \
            libfuse2 \
            x11-utils \
            x11-xfs-utils \
            x11-xkb-utils \
            x11-xserver-utils \
            x11vnc \
            xauth \
            xbindkeys \
            xclip \
            xcvt \
            xdotool \
            xfishtank \
            xfonts-base \
            xinit \
            xinput \
            xorg \
            xserver-xorg-core \
            xserver-xorg-input-evdev \
            xserver-xorg-input-libinput \
            xserver-xorg-legacy \
            xserver-xorg-video-all \
            xserver-xorg-video-dummy \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/* \
    && \
    echo

# Install audio requirements
ENV \
    PULSE_SOCKET_DIR="/tmp/pulse" \
    PULSE_SERVER="unix:/tmp/pulse/pulse-socket"
RUN \
    echo "**** Update apt database ****" \
        && apt-get update \
    && \
    echo "**** Install pulseaudio requirements ****" \
        && apt-get install -y --no-install-recommends \
            pulseaudio \
            alsa-utils \
            libasound2 \
            libasound2-plugins \
            libasound2:i386 \
            libasound2-plugins:i386 \
            libpulse0:i386 \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/* \
    && \
    echo

# Install desktop environment
# TODO: Specify all needed packages and add '--no-install-recommends'
RUN \
    echo "**** Update apt database ****" \
        && apt-get update \
    && \
    echo "**** Install desktop requirements ****" \
        && apt-get install -y --no-install-recommends \
            libdbus-1-3 \
            libegl1 \
            libgtk-3-0 \
            libgtk2.0-0 \
            libsdl2-2.0-0 \
    && \
    echo "**** Install desktop environment ****" \
        && apt-get install -y \
            firefox-esr \
            fonts-vlgothic \
            gedit \
            imagemagick \
            msttcorefonts \
            xdg-utils \
            xfce4 \
            xfce4-terminal \
            xterm \
        # Delete these as they are not needed at all
        && rm -f \
            /usr/share/applications/software-properties-drivers.desktop \
            /usr/share/applications/xfce4-about.desktop \
            /usr/share/applications/xfce4-session-logout.desktop \
        # Hide these apps. Missing desktop files must not fail the image build.
        && { [ ! -f /usr/share/applications/xfce4-accessibility-settings.desktop ] || sed -i '/^\[Desktop Entry\]$/a\NoDisplay=true' /usr/share/applications/xfce4-accessibility-settings.desktop; } \
        && { [ ! -f /usr/share/applications/xfce4-color-settings.desktop ] || sed -i '/^\[Desktop Entry\]$/a\NoDisplay=true' /usr/share/applications/xfce4-color-settings.desktop; } \
        && { [ ! -f /usr/share/applications/xfce4-mail-reader.desktop ] || sed -i '/^\[Desktop Entry\]$/a\NoDisplay=true' /usr/share/applications/xfce4-mail-reader.desktop; } \
        && { [ ! -f /usr/share/applications/xfce4-web-browser.desktop ] || sed -i '/^\[Desktop Entry\]$/a\NoDisplay=true' /usr/share/applications/xfce4-web-browser.desktop; } \
        && { [ ! -f /usr/share/applications/vim.desktop ] || sed -i '/^\[Desktop Entry\]$/a\NoDisplay=true' /usr/share/applications/vim.desktop; } \
        && { [ ! -f /usr/share/applications/thunar-settings.desktop ] || sed -i '/^\[Desktop Entry\]$/a\NoDisplay=true' /usr/share/applications/thunar-settings.desktop; } \
        && { [ ! -f /usr/share/applications/thunar.desktop ] || sed -i '/^\[Desktop Entry\]$/a\NoDisplay=true' /usr/share/applications/thunar.desktop; } \
        && { [ ! -f /usr/share/applications/pavucontrol.desktop ] || sed -i '/^\[Desktop Entry\]$/a\NoDisplay=true' /usr/share/applications/pavucontrol.desktop; } \
        && { [ ! -f /usr/share/applications/x11vnc.desktop ] || sed -i '/^\[Desktop Entry\]$/a\NoDisplay=true' /usr/share/applications/x11vnc.desktop; } \
        && { [ ! -f /usr/share/applications/display-im6.q16.desktop ] || sed -i '/^\[Desktop Entry\]$/a\NoDisplay=true' /usr/share/applications/display-im6.q16.desktop; } \
        # These are named specifically for Debian
        && { [ ! -f /usr/share/applications/debian-xterm.desktop ] || sed -i '/^\[Desktop Entry\]$/a\NoDisplay=true' /usr/share/applications/debian-xterm.desktop; } \
        && { [ ! -f /usr/share/applications/debian-uxterm.desktop ] || sed -i '/^\[Desktop Entry\]$/a\NoDisplay=true' /usr/share/applications/debian-uxterm.desktop; } \
        # Force these apps to be "System" apps rather than "Categories=System;Utility;Core;GTK;Filesystem;"
        && { [ ! -f /usr/share/applications/xfce4-appfinder.desktop ] || sed -i 's/^Categories=.*$/Categories=System;/' /usr/share/applications/xfce4-appfinder.desktop; } \
        && { [ ! -f /usr/share/applications/thunar-bulk-rename.desktop ] || sed -i 's/^Categories=.*$/Categories=System;/' /usr/share/applications/thunar-bulk-rename.desktop; } \
        && { [ ! -f /usr/share/applications/org.gnome.gedit.desktop ] || sed -i 's/^Categories=.*$/Categories=System;/' /usr/share/applications/org.gnome.gedit.desktop; } \
    && \
    echo "**** Install WoL Manager requirements ****" \
        && apt-get install -y \
            tcpdump \
            xprintidle \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/* \
    && \
    echo

# Add support for Flatpaks and D-Bus system services used by the current overlay
ENV \
    XDG_DATA_DIRS="/home/default/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share/:/usr/share/"
RUN \
    echo "**** Update apt database ****" \
        && apt-get update \
    && \
    echo "**** Install D-Bus system services for desktop integration ****" \
        && apt-get install -y --no-install-recommends \
            accountsservice \
            polkitd \
            pkexec \
    && \
    echo "**** Install Flatpak support ****" \
        && apt-get install -y --no-install-recommends \
            flatpak \
            gnome-software-plugin-flatpak \
    && \
    echo "**** Configure Flatpak ****" \
        && flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo \
        && dpkg-statoverride --update --add root root 0755 /usr/bin/bwrap \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/* \
    && \
    echo

# Install Web Frontend
ARG FRONTEND_VERSION=a8eb92fcdbf2e1c10befc90e61c9e16008db5476
ARG FRONTEND_SHA256=a55b0175a12e2038a352e0fd10a775644d278d0f9f7a069b750ffdc3d677db2d
ARG NOVNC_VERSION=90455eef0692d2e35276fd31286114d0955016b0
ARG NOVNC_SHA256=a2f7ff09d9d04a0087e96fcd2e34b009e20ac5dc7c1f1446eceb2e38492b40dd
RUN \
    echo "**** Fetch Web Frontend ****" \
        && wget -qO /tmp/frontend.tar.gz \
            "https://github.com/Steam-Headless/frontend/archive/${FRONTEND_VERSION:?}.tar.gz" \
        && wget -qO /tmp/novnc.tar.gz \
            "https://github.com/novnc/noVNC/archive/${NOVNC_VERSION:?}.tar.gz" \
        && echo "${FRONTEND_SHA256:?}  /tmp/frontend.tar.gz" | sha256sum -c - \
        && echo "${NOVNC_SHA256:?}  /tmp/novnc.tar.gz" | sha256sum -c - \
        && rm -rf /opt/frontend \
        && mkdir -p /opt/frontend/noVNC \
        && tar -xzf /tmp/frontend.tar.gz -C /opt/frontend --strip-components=1 \
        && tar -xzf /tmp/novnc.tar.gz -C /opt/frontend/noVNC --strip-components=1 \
    && \
    echo "**** Configure Web Frontend ****" \
        && echo '<!DOCTYPE html>' > /opt/frontend/index.html \
        && echo '<html><head><meta http-equiv="refresh" content="0;url=./web/"></head><body><p>If you are not redirected, <a href="./web/">click here</a>.</p></body></html>' >> /opt/frontend/index.html \
        && chmod -R 755 /opt/frontend \
        && convert /opt/frontend/web/images/icons/novnc-ios-180.png -resize "128x128" /tmp/steam-headless.png \
        && xdg-icon-resource install --novendor --size 128 /tmp/steam-headless.png \
    && \
    echo "**** Section cleanup ****" \
        && rm -f \
            /tmp/frontend.tar.gz \
            /tmp/novnc.tar.gz \
            /tmp/steam-headless.png

# Install Websockify
ARG WEBSOCKETIFY_VERSION=0.13.0
ARG WEBSOCKETIFY_SHA256=b6413e364efd04f3c92ec8c17747e3c4adc20157c2ef1c5d019a26d944a46df8
RUN \
    echo "**** Update apt database ****" \
        && apt-get update \
    && \
    echo "**** Install Websockify dependencies ****" \
        && apt-get install -y \
            python3-numpy \
            python3-requests \
            python3-jwcrypto \
            python3-redis \
    && \
    echo "**** Fetch Websockify ****" \
        && cd /tmp \
        && wget -O /tmp/websockify.tar.gz https://github.com/novnc/websockify/archive/refs/tags/v${WEBSOCKETIFY_VERSION}.tar.gz \
        && echo "${WEBSOCKETIFY_SHA256:?}  /tmp/websockify.tar.gz" | sha256sum -c - \
    && \
    echo "**** Extract Websockify ****" \
        && cd /tmp \
        && tar -xvf /tmp/websockify.tar.gz \
    && \
    echo "**** Install Websockify to Web Frontend path ****" \
        && cd /tmp \
        && mv -v /tmp/websockify-${WEBSOCKETIFY_VERSION} /opt/frontend/utils/websockify \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /tmp/websockify-* \
            /tmp/websockify.tar.gz

# Setup audio streaming deps
RUN \
    echo "**** Update apt database ****" \
        && apt-get update \
    && \
    echo "**** Install audio streaming deps ****" \
        && apt-get install -y --no-install-recommends \
            bzip2 \
            gstreamer1.0-alsa \
            gstreamer1.0-gl \
            gstreamer1.0-gtk3 \
            gstreamer1.0-libav \
            gstreamer1.0-plugins-bad \
            gstreamer1.0-plugins-base \
            gstreamer1.0-plugins-good \
            gstreamer1.0-plugins-ugly \
            gstreamer1.0-pulseaudio \
            gstreamer1.0-qt5 \
            gstreamer1.0-tools \
            gstreamer1.0-vaapi \
            gstreamer1.0-x \
            libgstreamer1.0-0 \
            libncursesw5 \
            libopenal1 \
            libsdl-image1.2 \
            libsdl-ttf2.0-0 \
            libsdl1.2debian \
            libsndfile1 \
            ucspi-tcp \
            gstreamer1.0-plugins-base:i386 \
            gstreamer1.0-plugins-good:i386 \
            gstreamer1.0-plugins-bad:i386 \
            gstreamer1.0-plugins-ugly:i386 \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/* \
    && \
    echo

# Setup video streaming deps
RUN \
    echo "**** Update apt database ****" \
        && apt-get update \
    && \
    echo "**** Install Intel media drivers and VAAPI ****" \
        && apt-get install -y --no-install-recommends \
            intel-media-va-driver-non-free \
            i965-va-driver-shaders \
            libva2 \
            libvulkan1 \
            libvulkan1:i386 \
            mesa-utils \
            mesa-vulkan-drivers \
            mesa-vulkan-drivers:i386 \
            vulkan-tools \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/* \
    && \
    echo

# Install tools for monitoring hardware
RUN \
    echo "**** Update apt database ****" \
        && apt-get update \
    && \
    echo "**** Install useful HW monitoring tools ****" \
        && apt-get install -y --no-install-recommends \
            cpu-x \
            htop \
            vainfo \
            vdpauinfo \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/* \
    && \
    echo

# Install Steam
RUN \
    echo "**** Update apt database ****" \
        && apt-get update \
    && \
    echo "**** Install Steam ****" \
        && apt-get install -y --no-install-recommends \
            steam-installer \
        && ln -sf /usr/games/steam /usr/bin/steam \
    && \
    echo "**** Allow an explicitly requested unattended first Steam bootstrap ****" \
        && sed -i \
            '0,/^if \[ -n "$new_installation" \]; then$/s//if [ -n "$new_installation" ] \&\& [ "${STEAM_AUTO_INSTALL:-false}" != "true" ]; then/' \
            /usr/games/steam \
        && grep -Fq '${STEAM_AUTO_INSTALL:-false}' /usr/games/steam \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/* \
    && \
    echo

# Sunshine no longer publishes a Debian Bookworm package. Install the official
# self-contained AppImage instead of mixing a Debian Trixie package into this
# Bookworm image. Extract it at build time so runtime does not require another
# FUSE mount.
ARG SUNSHINE_VERSION=2026.516.143833
ARG SUNSHINE_APPIMAGE_SHA256=d0ee0a9cfb66f27869b559455f84622d21615047ccf3443c9a2f572ca971c7a2
RUN \
    echo "**** Update apt database ****" \
        && apt-get update \
    && \
    echo "**** Install Sunshine requirements ****" \
        && apt-get install -y \
            libayatana-appindicator3-1 \
            libnotify4 \
            va-driver-all \
    && \
    echo "**** Install Sunshine ****" \
        && wget --quiet \
            -O /tmp/sunshine.AppImage \
            "https://github.com/LizardByte/Sunshine/releases/download/v${SUNSHINE_VERSION}/sunshine.AppImage" \
        && echo "${SUNSHINE_APPIMAGE_SHA256:?}  /tmp/sunshine.AppImage" | sha256sum -c - \
        && chmod 0755 /tmp/sunshine.AppImage \
        && cd /opt \
        && /tmp/sunshine.AppImage --appimage-extract >/dev/null \
        && mv /opt/squashfs-root /opt/sunshine \
        && install -d /usr/share/icons/hicolor \
        && cp -a \
            /opt/sunshine/usr/share/icons/hicolor/. \
            /usr/share/icons/hicolor/ \
        && test -f \
            /usr/share/icons/hicolor/scalable/apps/dev.lizardbyte.app.Sunshine.svg \
        && test -f \
            /usr/share/icons/hicolor/scalable/status/dev.lizardbyte.app.Sunshine-tray.svg \
        && { gtk-update-icon-cache \
            --force \
            --ignore-theme-index \
            /usr/share/icons/hicolor >/dev/null 2>&1 || true; } \
    && \
    echo "**** Section cleanup ****" \
        && apt-get clean autoclean -y \
        && apt-get autoremove -y \
        && rm -rf \
            /var/lib/apt/lists/* \
            /var/tmp/* \
            /tmp/* \
    && \
    echo

# TODO: Deprecate neko
# Install Neko server
COPY --from=m1k1o/neko:base@sha256:472c2bb548c6a0d01706ec97672c56ef75dc6a45084111ed88f0cf19c8fb2f52 /usr/bin/neko /usr/bin/neko
COPY --from=m1k1o/neko:base@sha256:472c2bb548c6a0d01706ec97672c56ef75dc6a45084111ed88f0cf19c8fb2f52 /var/www /var/www

# Various other tools
ARG DUMB_INIT_VERSION=1.2.5
ARG DUMB_INIT_SHA256=e874b55f3279ca41415d290c512a7ba9d08f98041b28ae7c2acb19a545f1c4df
ARG DUMB_UDEV_VERSION=64d1427
ARG DUMB_UDEV_SHA256=2dee1dd820d102b257c801dad9cff8aa8104b2720f678847667a3d03e6f18524
ARG MURMURHASH2_WHEEL_SHA256=ab1b141508358c6c30bc3c90a90267d8aa2eea4bfa5673d63da9c9b325dda77c
ARG PYUDEV_WHEEL_SHA256=da7e977be15fb5eccf8797b8e2176cd5b4f39288707cdcb39d1cabe7c8793e2b
RUN \
    echo "**** Install dumb-init ****" \
        && wget --quiet \
            -O /usr/bin/dumb-init \
            https://github.com/Yelp/dumb-init/releases/download/v${DUMB_INIT_VERSION}/dumb-init_${DUMB_INIT_VERSION}_x86_64 \
        && echo "${DUMB_INIT_SHA256:?}  /usr/bin/dumb-init" | sha256sum -c - \
        && chmod +x /usr/bin/dumb-init \
    && echo

RUN \
    echo "**** Install dumb-udev ****" \
        && wget -qO /tmp/dumb-udev.tar.gz \
            "https://github.com/Steam-Headless/dumb-udev/archive/${DUMB_UDEV_VERSION:?}.tar.gz" \
        && wget -qO /tmp/murmurhash2-0.2.10-cp36-abi3-manylinux_2_5_x86_64.manylinux1_x86_64.whl \
            "https://files.pythonhosted.org/packages/db/48/508bce44ee1f3a4c2059ee7ddfb5764c0d8c71e8e10b8dadf63667f86850/murmurhash2-0.2.10-cp36-abi3-manylinux_2_5_x86_64.manylinux1_x86_64.whl" \
        && wget -qO /tmp/pyudev-0.24.1-py3-none-any.whl \
            "https://files.pythonhosted.org/packages/87/1d/82b016f11cd15e8ebcb01132cbe36039ce122c15c51341de9fcbe10483ae/pyudev-0.24.1-py3-none-any.whl" \
        && echo "${DUMB_UDEV_SHA256:?}  /tmp/dumb-udev.tar.gz" | sha256sum -c - \
        && echo "${MURMURHASH2_WHEEL_SHA256:?}  /tmp/murmurhash2-0.2.10-cp36-abi3-manylinux_2_5_x86_64.manylinux1_x86_64.whl" | sha256sum -c - \
        && echo "${PYUDEV_WHEEL_SHA256:?}  /tmp/pyudev-0.24.1-py3-none-any.whl" | sha256sum -c - \
        && python3 -m pip install \
            --break-system-packages \
            --no-cache-dir \
            --no-deps \
            --no-index \
            /tmp/murmurhash2-0.2.10-cp36-abi3-manylinux_2_5_x86_64.manylinux1_x86_64.whl \
            /tmp/pyudev-0.24.1-py3-none-any.whl \
        && mkdir -p /tmp/dumb-udev-src \
        && tar -xzf /tmp/dumb-udev.tar.gz \
            -C /tmp/dumb-udev-src \
            --strip-components=1 \
        && printf \
            '{"short":"0.0.0+%s","long":"0.0.0+%s"}\n' \
            "${DUMB_UDEV_VERSION:?}" \
            "${DUMB_UDEV_VERSION:?}" \
            >/tmp/dumb-udev-src/dumb_udev/version \
        && python_site_dir="$(python3 -c 'import sysconfig; print(sysconfig.get_path("purelib"))')" \
        && install -d "${python_site_dir}" \
        && cp -a /tmp/dumb-udev-src/dumb_udev "${python_site_dir}/dumb_udev" \
        && printf '%s\n' \
            '#!/usr/bin/python3' \
            'from dumb_udev.service import main' \
            'main()' \
            >/usr/local/bin/dumb-udev \
        && chmod 0755 /usr/local/bin/dumb-udev \
        && python3 -c 'import dumb_udev.service, murmurhash2, pyudev' \
        && rm -rf \
            /tmp/dumb-udev-src \
            /tmp/dumb-udev.tar.gz \
            /tmp/murmurhash2-0.2.10-cp36-abi3-manylinux_2_5_x86_64.manylinux1_x86_64.whl \
            /tmp/pyudev-0.24.1-py3-none-any.whl \
    && echo

# Add FS overlay
COPY overlay /
# Do not depend on executable bits surviving macOS, SMB, or Unraid copies.
# Init scripts run as root, while Supervisor launches several scripts only
# after dropping privileges to the default user.
RUN \
    chmod 0755 \
        /etc/cont-init.d/*.sh \
        /usr/bin/common-functions.sh \
        /usr/bin/configure_firefox.sh \
        /usr/bin/drop_caches.sh \
        /usr/bin/install_flatseal.sh \
        /usr/bin/install_protonup.sh \
        /usr/bin/open-sunshine-webui.sh \
        /usr/bin/set-custom-res.sh \
        /usr/bin/sunshine \
        /usr/bin/start-*.sh \
        /usr/bin/steam-headless-wol-power-manager \
        /usr/bin/sunshine-run \
        /usr/bin/sunshine-stop \
        /usr/bin/xfce4-close-all-windows \
        /usr/bin/xfce4-minimise-all-windows

# Set display environment variables
ENV \
    DISPLAY_CDEPTH="24" \
    DISPLAY_REFRESH="120" \
    DISPLAY_SIZEH="900" \
    DISPLAY_SIZEW="1600" \
    DISPLAY_VIDEO_PORT="DP-0" \
    XORG_MODE_DEBUG="false" \
    DISPLAY=":55"
ENV \
    NVIDIA_DRIVER_CAPABILITIES="all" \
    NVIDIA_VISIBLE_DEVICES="all" \
    NVIDIA_PRIMARY_GPU=""

# Set container configuration environment variables
# TODO: Set the default WEBUI_USER & WEBUI_PASS after release of SHUI
ENV \
    MODE="primary" \
    WEB_UI_MODE="vnc" \
    ENABLE_VNC_AUDIO="true" \
    NEKO_PASSWORD=neko \
    NEKO_PASSWORD_ADMIN=admin \
    ENABLE_STEAM="true" \
    STEAM_AUTO_INSTALL="true" \
    STEAM_ARGS="-silent" \
    WEBUI_USER="" \
    WEBUI_PASS="" \
    ENABLE_SUNSHINE="true" \
    SUNSHINE_CSRF_ALLOWED_ORIGINS="" \
    ENABLE_EVDEV_INPUTS="true" \
    ENABLE_WOL_POWER_MANAGER="false"

# Configure required ports
ENV \
    PORT_NOVNC_WEB="8083" \
    NEKO_NAT1TO1=""

# Expose the required ports
EXPOSE 8083

# Set entrypoint
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
