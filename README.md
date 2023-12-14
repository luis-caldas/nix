# My NIX

This project aims to be a faster configuration system for nixos, based on my preferences

# Understanding it

## Creating a specific system configuration

The system specific configurations are stored inside the `config/` folder

Each system has its own subfolder with the files `config.json` and `hardware.nix` inside it

More complex configurations can be achieved with linking more `.nix` files to your `hardware.nix` file

### `hardware.nix`

This file is generated by the nixos `nixos-generate-config` utility and simply copied over to the system specific folder

### `config.json`

A dumbed down and faster way to do small changes between systems while maintaining my overall configuration untouched

The `default.json` file inside the `config/` folder contains all the possible entries for configuration, the `config.json` uses the same keys as the `deafult.json` file, so different systems may have slightly different configurations

The `check.py` file inside the `config/` folder is a python script used to check mismatches and redundancy between `default.json` and `config.json` files

# Other folders and files

## `common`

These are the common configurations between all my systems

They are separated between `system` and `user` and makes use of the configuration keys set in the `config.json`

### `system`

Common configuration files for the whole system

### `user`

Common user configuration files, also has its files separated between the `home-manager` files and normal files

## `functions`

The files inside this folder are **nix** functions used throughout the project

## `pkgs`

My own collection of packages, made in the same format as `nixpkgs`

## `iso`

This folder contains files used to create a bootable nixos iso (made with my configurations)

This ISO will use the `iso` configuration scheme found in the `config` folder at the root directory

There is a bash script also with the proper command to generate the iso

## `linker.nix`

This file links all the projects file into a single point, so it can be easily referenced later

## `config.nix`

This file imports all configurations to the linker

## `system.skeleton`

Reference file set as an example for the `system` file

# Finally building it

A file named `system` in the root of the project is needed in order to select the system that is going to be built, it is a simple plain text file with the systems name inside

For the commands `nixos-rebuild` or `nixos-install` to work the file `linker.nix` must be imported from your `/etc/nixos/configuration.nix` file

# Extra

### Warnings

When installing it to a new system some git projects won't be copied due to a `nixos-install` bug, the workaround would be to run the following command

`nix-build '<nixpkgs/nixos>' -A config.system.build.toplevel -I nixos-config=/mnt/etc/nixos/configuration.nix`

The command then fetches the projects into your host `/nix` folder and is capable of proceeding with the installation after

### Useful ZFS flags

Taken from <https://elis.nu/blog/2019/08/encrypted-zfs-mirror-with-mirrored-boot-on-nixos/>

Disable ZFS automatic mounting:

   `-O mountpoint=none`

Disable writing access time:

   `-O atime=off`

Use 4K sectors on the drive, otherwise you can get really bad performance:

   `-o ashift=12`

This is more or less required for certain things to not break:

   `-O acltype=posixacl`

To improve performance of certain extended attributes:

   `-O xattr=sa`

To enable file system compression:

   `-O compression=lz4`

To enable encryption:

   `-O encryption=aes-256-gcm -O keyformat=passphrase`

To disable sync on the `tmp` partition:

   `-o sync=disabled`

To enable auto-trim on SSDs:

   `-o autotrim=on`

### Swap on ZFS

To create a `zvol` for swap:

```
zfs create -V {size in GB}G -b 8192 \
    -o logbias=throughput -o sync=always\
    -o primarycache=metadata -o secondarycache=none \
    -o com.sun:auto-snapshot=false {pool name}/swap
```

Formatting:

```
mkswap -f /dev/zvol/{pool name}/swap
```

### AWS EC2

The following things are needed for a proper installation

 - Change root password
 - SWAP
 - SSH Keys
 - Directory Structure
 - WireGuard Keys
 - TMPDIR for Rebuild

### Data Organising Convention

All data if not at home directory should be stored at `/data`

`/data/{drive name}/{partition name}/{first distinction}/{second distinction}/{specifics}`

Drive name would not be needed if there is only one drive, example of drive names are `local`, `store`, `bunker`

Partition name would not be needed if only a single partition from a single drive is used, the name of the folder should reflect the partition name

The first distinction should be named specifically as what it is, for example `container`, `storage`

Second distinction only needed if deemed necessary, it should then be named as what the distinction is about like if a subdivision in an application

Specifics of certain distinction should all be together and not scattered across other folders, sometimes specifications may also not be needed, certain specifics can be `env`, `safe`, `config`
