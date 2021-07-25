{ my, mfunc, ... }:
let

  # Set GRUB
  tempGrub = {

    # Basic
    enable = true;
    version = 2;

    # Try to identify other systems
    useOSProber = my.config.boot.prober;

    # Enable Memtest
    memtest86.enable = true;

    # EFI support
    efiInstallAsRemovable = my.config.boot.efi;
    efiSupport = my.config.boot.efi;

    # ZFS support
    zfsSupport = true;

    # Force true text modes
    gfxpayloadBios = "text";
    gfxpayloadEfi = "text";

    # Set grub to console mode
    extraConfig = "
      terminal_input console
      terminal_output console
    ";

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

    # Support for zfs
    supportedFilesystems = [ "zfs" "ntfs" ];

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
