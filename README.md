# Headless Steam Service

![](./images/banner.jpg)

Remote Game Streaming Server.

Play your games either in the browser with audio or via Steam Link or Moonlight. Play from another Steam Client with Steam Remote Play.

Easily deploy a Steam Docker instance in seconds.

## Features:
- Steam Client configured for running on Linux with Proton
- Moonlight compatible server for easy remote desktop streaming
- Easy installation of EmeDeck, Heroic and Lutris via Flatpak
- Full video/audio noVNC web access to a Xfce4 Desktop
- NVIDIA, AMD and Intel GPU support
- Full controller support
- Support for Flatpak and Appimage installation
- Root access
- Based on Debian Trixie

---
## Notes:

### ADDITIONAL SOFTWARE:
If you wish to install additional applications, you can generate a script inside the `~/init.d` directory ending with ".sh".
This will be executed on the container startup.

Also, you can install applications using the WebUI under **Applications > System > Software**. There you can install other game launchers like Lutris, Heroic or EmuDeck.

### STORAGE PATHS:
Everything that you wish to save in this container should be stored in the home directory or a docker container mount that you have specified. 
All files that are store outside your home directory are not persistent and will be wiped if there is an update of the container or you change something in the template.

### GAMES LIBRARY:
It is recommended that you mount your games library to `/mnt/games` and configure Steam to add that path.

### UPGRADING FROM BOOKWORM:
Existing appdata can be reused when upgrading to the Trixie image. During
upgrade testing, Steam initially reopened its UI when the window was closed.
Fully exiting and relaunching Steam once cleared the stale session state, and
the fix persisted across container restarts. Try this before resetting existing
appdata if the same behavior occurs.

### GAMESCOPE:
Gamescope is not installed by default. Debian Trixie currently publishes it
through backports rather than the base repository, and nested operation in this
headless NVIDIA/Xorg configuration has not yet been revalidated.

### AUTO START APPLICATIONS:
In this container, Steam is configured to automatically start. If you wish to add additional services to automatically start, 
add them under **Applications > Settings > Session and Startup** in the WebUI.

### NETWORK MODE:
Use host networking for a standalone primary container. Sunshine creates its
input devices after Xorg starts, and Xorg must receive the corresponding udev
hotplug events from the host network namespace. A custom macvlan or ipvlan IP
can stream video while leaving Moonlight keyboard, mouse, and controller input
unavailable. See the platform installation guides for the required device and
capability settings.

### USING HOST X SERVER:
If your host is already running X, you can just use that. To do this, be sure to configure:
  - DISPLAY=:0    
    **(Variable)** - *Configures the sceen to use the primary display. Set this to whatever your host is using*
  - MODE=secondary    
    **(Variable)** - *Configures the container to not start an X server of its own*
  - HOST_DBUS=true    
    **(Variable)** - *Optional - Configures the container to use the host dbus process*
  - /run/dbus:/run/dbus:ro    
    **(Mount)**  - *Optional - Configures the container to use the host dbus process*


---
## Installation:
- [Docker Compose](./docs/docker-compose.md)
- [Unraid](./docs/unraid.md)
- [Ubuntu Server](./docs/ubuntu-server.md)


---
## Running locally:

For a development environment, I have created a script in the devops directory.


---
## TODO:
- Remove SSH
- Require user to enter password for sudo
- Evaluate replacing the pinned Sunshine AppImage with the pinned native
  `sunshine-debian-trixie-amd64.deb`. Verify container-safe package installation,
  udev/capability setup, the shared launcher, NVENC, Moonlight input, tray
  behavior, and final image size.
- Install Gamescope from Trixie backports and test nested operation with the
  headless NVIDIA/Xorg configuration before enabling it by default.
- Document how to run this container:
    - Other server OS
    - TrueNAS Scale 
