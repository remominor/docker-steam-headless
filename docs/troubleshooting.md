## Flatpaks not working

Flatpaks are installed into the `default` user's home directory so they persist between container updates. Apps installed from the Software application should appear under `<SteamHeadless Home>/.local/share/flatpak`. A Flatpak shown as a `system` installation instead lives in the disposable container layer and should be reinstalled for the user.

Check the installation scope with:

```shell
flatpak list --app --columns=application,installation,branch
```

Reinstall an application persistently with:

```shell
flatpak --user install flathub <application-id>
```

Flatpak's bubblewrap sandbox also needs permission to mount a private `/proc` inside the container. Docker Compose deployments should include `systempaths:unconfined` under `security_opt`. For Unraid, add `--security-opt='systempaths=unconfined'` to the container's Extra Parameters and recreate the container. Without it, applications fail with `bwrap: Can't mount proc on /newroot/proc: Operation not permitted` followed by `ldconfig failed, exit status 256`. On NVIDIA systems, the container startup scripts also remove the runtime-injected `/proc/driver/nvidia/params` submount because any separate mount below `/proc` blocks the same nested sandbox operation.

Sometimes Flatpak runtimes can become inconsistent between major Steam Headless updates. In that case:

1) Stop the container.
2) Delete the directory `<SteamHeadless Home>/.local/share/flatpak`
3) Re-create the container. Don't just restart it. This will trigger an update of the required Flatpak runtimes in the home directory.
4) Reinstall any missing Flatpaks from the Software app.

Once your Flatpak refresh is complete, everything should work correctly and your configuration for each application should have remained intact.

## An error occurred while installing <game>: "disk write error"

![img.png](./images/disk_write_error.png)

1) Stop the container
2) Verify your mounted /mnt/games volume is owned by the executing UID/GID, and 777 permissions are set.
3) Verify the `steamapps` directory exists within the library location. 

> __Note__
>
> The directory in the below commands are the default /mnt/games library locations installed upon first execution of this container.
> 
> Depending on how you have installed this, the directory path may vary.

```shell
sudo mkdir /mnt/games/GameLibrary/SteamLibrary/steamapps
sudo chmod -R 777 /mnt/games
sudo chown -R $(id -u):$(id -g) /mnt/games
```
