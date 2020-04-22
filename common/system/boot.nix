{ ... }:
let
  my = import ../../config.nix;
in
{

  # Main boot configuration
  boot = { 

    # Force kernel support for zfs
    kernelParams = ["zfs_force=1"] ++ my.config.kernel.params;
    supportedFilesystems = ["zfs"];

    # Don't force import zfs pool
    zfs = {
      forceImportRoot = false;
      forceImportAll = false;
    };

    # Bootloader configuration
    loader = {

      # Just for fast bois
      timeout = my.config.boot.timeout;
      
      # Set GRUB
      grub = {

        # Basic
        enable = true;
        version = 2;

        # Try to identify other systems
        useOSProber = true;

        # EFI support
        efiInstallAsRemovable = my.config.boot.efi;
        efiSupport = my.config.boot.efi;

        # Which GRUB entry should be booted first
        default = my.config.boot.default;

        # Eye candy
        splashImage = null;

        # Specify the devices
        devices = [my.config.boot.device];

      };

    };

  };

}
