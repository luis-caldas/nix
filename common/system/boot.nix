{ my, mfunc, ... }:
let

  # Set GRUB
  tempGrub = {

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

  # Check if the user configuration overrides boot information
  realGrub = mfunc.useDefault my.config.boot.override {} tempGrub;

in
{

  # Unset the nixos font
  console.font = "";

  # Main boot configuration
  boot = {

    # Disable pesky kernel messages at boot
    consoleLogLevel = 0;

    # Force kernel support for zfs
    kernelParams = ["zfs_force=1"] ++ my.config.kernel.params;
    supportedFilesystems = ["zfs"];

    # For RTL-SDR
    blacklistedKernelModules = [ "dvb_usb_rtl28xxu" ];

    # Don't force import zfs pool
    zfs = {
      forceImportRoot = false;
      forceImportAll = false;
    };

    # Bootloader configuration
    loader = {

      # Just for fast bois
      timeout = my.config.boot.timeout;

      # Set the grub if configured to do so
      grub = realGrub;

    };

  };

}
