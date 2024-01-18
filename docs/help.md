## ZFS Creating

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

SWAP should not be used with ZFS

To create a `zvol` for swap:

```
zfs create -V {size in GB}G -b 8192 \
    -o logbias=throughput -o sync=always\
    -o primarycache=metadata -o secondarycache=none \
    -o com.sun:auto-snapshot=false {pool name}/swap
```

Path is found at:

```
/dev/zvol/{pool name}/swap
```
