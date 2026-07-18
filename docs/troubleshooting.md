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

Flatpak's bubblewrap sandbox also needs to mount a private `/proc` inside the container. At startup, Steam Headless mounts a clean procfs over the container's existing `/proc`. This covers Docker's masked and read-only procfs submounts together with runtime additions such as `/proc/driver/nvidia/params`, allowing the nested sandbox to start without `systempaths=unconfined`. Keep the documented `SYS_ADMIN` capability in the container configuration; it is required for this procfs remount.

If an application fails with `bwrap: Can't mount proc on /newroot/proc: Operation not permitted` followed by `ldconfig failed, exit status 256`, check the container startup log for `Could not mount a clean procfs`. Verify that `SYS_ADMIN` and `seccomp:unconfined` are still configured, then recreate the container. The older `systempaths=unconfined` workaround is no longer required and can be removed from Unraid Extra Parameters or Docker Compose.

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
