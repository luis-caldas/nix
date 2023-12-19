## Useful ZFS flags

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

## Swap on ZFS

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

### Data Organising Convention

All data if not at home directory should be stored at `/data`

`/data/{drive name}/{partition name}/{first distinction}/{second distinction}/{specifics}`

Drive name would not be needed if there is only one drive, example of drive names are `local`, `store`, `bunker`

Partition name would not be needed if only a single partition from a single drive is used, the name of the folder should reflect the partition name

The first distinction should be named specifically as what it is, for example `container`, `storage`

Second distinction only needed if deemed necessary, it should then be named as what the distinction is about like if a subdivision in an application

Specifics of certain distinction should all be together and not scattered across other folders, sometimes specifications may also not be needed, certain specifics can be `env`, `safe`, `config`
