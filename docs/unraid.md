# Unraid

Follow these instructions to install Steam Headless on Unraid

## CONTAINER TEMPLATE:

1. Navigate to "**APPS**" tab.
2. Search for "*steam-headless*"
3. Select either **Install** or **Actions > Install** from the search result.
![](./images/install-steam-headless-unraid-ca.png)
4. Configure the template as required.


## GPU CONFIGURATION:

This container can use your dedicated GPU. 
In order for it to do this you need to have either the Nvidia-Driver or Radeon-Top plugin installed.

### NVIDIA

1. Install the [Nvidia-Driver Plugin](https://forums.unraid.net/topic/98978-plugin-nvidia-driver/) by [ich777](https://forums.unraid.net/profile/72388-ich777/). This will maintain an up-to-date NVIDIA driver installation on your Unraid server.
![](./images/unraid-nvidia-plugin.png)
2. Toggle the steam-headless Docker Container template editor to "**Advanced View**".
3. In the "**Extra Parameters**" field, ensure that you have the `--runtime=nvidia` parameter added.
![](./images/unraid-steam-headless-template-nvidia-extra-params.png)
4. Expand **Show more settings...** near the bottom of the template and set
   **Nvidia GPU UUID** (`NVIDIA_VISIBLE_DEVICES`). Normally this is the UUID of
   the GPU assigned to the container. On affected multi-GPU driver versions,
   use the comma-separated workaround described below. The UUIDs are shown by
   the Unraid Nvidia Driver plugin or by `nvidia-smi -L`.
5. Use one GPU-selection mechanism. When `NVIDIA_VISIBLE_DEVICES` contains the
   selected UUID or UUID list, do not also add a conflicting
   `--gpus=device=...` selector to **Extra Parameters**. Leave
   `NVIDIA_DRIVER_CAPABILITIES=all` enabled because the container requires
   compute, graphics, utility, video, and display capabilities.
6. Do not install or select an NVIDIA driver version inside the container. The
   NVIDIA runtime supplies userspace libraries and the Xorg module that match
   the Unraid host driver. The container validates those files at startup.

#### NVENC on multi-GPU hosts

NVIDIA Linux driver branches 570, 580, and 595 have a known container
regression on multi-GPU hosts when only a subset of the GPUs is exposed. CUDA
and Xorg may work while FFmpeg and Sunshine fail with
`OpenEncodeSessionEx failed: unsupported device (2)`. NVIDIA reports the fix in
the 610 driver branch. Prefer a 610-or-newer Unraid NVIDIA driver when it is
available for the installed Unraid kernel. See the
[NVIDIA multi-GPU NVENC discussion](https://forums.developer.nvidia.com/t/nvenc-and-nvdec-work-on-only-one-gpu-with-multi-gpu-setups-with-nvidia-container-toolkit-in-driver-565/347361).

If an affected driver must be retained, expose every NVIDIA GPU to the
container as a comma-separated UUID list. Put the GPU that should run Xorg and
Sunshine first; the container uses the first UUID as its primary display GPU.
For example:

```text
NVIDIA_VISIBLE_DEVICES=GPU-primary-uuid,GPU-secondary-uuid
```

This works around the driver's peer-GPU initialization bug, but intentionally
gives the container access to every listed GPU. Merely adding the secondary
`/dev/nvidiaN` node is insufficient because the NVIDIA runtime must also include
that GPU in its logical visible-device set. This configuration has been
validated with two RTX 3070 GPUs and driver 595.84: Bookworm FFmpeg successfully
encoded H.264 through `h264_nvenc` on logical GPU 0 after both UUIDs were made
visible.

### X11 AND PULSE SOCKETS

A standalone container running with `MODE=primary` starts its own Xorg and PulseAudio servers. It should normally use the socket directories inside the container.

Do not bind the host's `/tmp/.X11-unix` or `/tmp/pulse` directories into a standalone primary container. Shared socket mounts are only needed when another container running with `MODE=secondary` intentionally connects to this primary container's Xorg or PulseAudio server. Sharing the host directories unnecessarily can leave stale sockets behind and cause display-server restart conflicts.

### STEAM FIRST INSTALLATION

Debian's Steam launcher normally displays an Install/Cancel dialog before it
downloads the proprietary client into the persistent home directory. This
image defaults `STEAM_AUTO_INSTALL=true`, which skips only that dialog. Debian's
launcher still downloads the official archive and verifies its SHA-256 digest
before extracting it. Set `STEAM_AUTO_INSTALL=false` in the container template
if you prefer to approve the installation interactively.

### SUNSHINE WEB UI ORIGINS

Current Sunshine releases protect state-changing Web UI requests with CSRF
origin checks. On host networking, the startup script automatically adds the
host's private IPv4 interface addresses on a clean configuration. If you open
the Web UI through a DNS name, reverse proxy, or another address, add an
explicit `SUNSHINE_CSRF_ALLOWED_ORIGINS` variable containing a comma-separated
list such as `https://tower.local,https://192.168.1.10`. Existing values saved
in `sunshine.conf` are preserved.

### AMD

1. Install the [Radeon-Top Plugin](https://forums.unraid.net/topic/92865-support-ich777-amd-vendor-reset-coraltpu-hpsahba/) by [ich777](https://forums.unraid.net/profile/72388-ich777/).
![](./images/unraid-amd-plugin.png)
2. Profit


## FLATPAK APPLICATIONS:

Flatpak applications run a nested bubblewrap sandbox that mounts its own
`/proc`. Container startup mounts a clean, container-local procfs so Docker's
masked paths and NVIDIA runtime submounts do not block that sandbox. No
additional `systempaths=unconfined` security option is required. The container
must retain the supplied `SYS_ADMIN` capability so it can perform the procfs
remount.

Applications installed from the desktop Software application use the
persistent `default` user installation under
`/home/default/.local/share/flatpak`.


## REMOTE INPUT AND CONTROLLER SUPPORT:

Unraid's Linux kernel by default does not have the modules required to support controller input. Steam requires these modules to be able to create the virtual "Steam Input Gamepad Emulation" device that it can then map buttons to.

[ich777](https://forums.unraid.net/profile/72388-ich777/) has kindly offered to build and maintain the required modules for the Unraid kernel as he already has a CI/CD pipeline in place and a small number of other kernel modules that he is maintaining for other projects. So a big thanks to him for that!

> __Note__
>
> This may no longer be required with Unraid v6.11 release (TBD). The required uinput module should be added to the kernel for that release.

1. Install the **uinput** plugin from the **Apps** tab.
![](./images/unraid-steam-headless-install-uinput-plugin.png)
2. Set **Network Type** to **Host**. Sunshine creates keyboard, mouse, and
   controller devices through `/dev/uinput` after Xorg has started. Xorg must
   receive the resulting kernel udev events in order to attach those devices.
   Docker bridge, macvlan, and ipvlan networks use a separate network namespace
   and do not reliably deliver those hotplug events to Xorg in this container.

   A custom container IP may allow Sunshine video and audio to connect while
   leaving all Moonlight input nonfunctional. Enabling privileged mode or
   changing `/dev/uinput` permissions does not correct the isolated event
   namespace. Use host networking for the supported configuration.
![](./images/unraid-steam-headless-configure-network-as-host.png)

    > __Warning__
    >
    > Be aware that, by default, this container requires at least 8083 available for the WebUI to work. It will also require any ports that Steam requires for Steam Remote Play.

    You can override the default ports used by the container with these variables:
    - PORT_NOVNC_WEB (Default: 8083)
    - WEB_UI_MODE (Default: 'vnc' - Set to 'none' to disable the WebUI)

3. No server restart is normally required. Recreate the **steam-headless**
   container after installing the plugin or changing the network type so it can
   detect `/dev/uinput` and join the host network namespace.
