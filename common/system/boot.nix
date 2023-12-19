{ my, mfunc, ... }:
let

  # GRUB Configuration
  grubConfiguration = {

    # Basic
    enable = true;

    # ZFS fixes
    copyKernels = true;

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
    " +
    # Add a custom tune to the start if set
    (if my.config.boot.tune then "play 600 440 1 220 1 880 1 0 1 880 2" else "");

    # Which GRUB entry should be booted first
    default = my.config.boot.default;

    # Eye candy
    splashImage = null;

    # Specify the devices
    devices = [ my.config.boot.device ];

  };

  # Set systemd-boot configuration
  systemDBootConfiguration = {

    # Enable it and disable command line editing
    enable = true;
    editor = false;

    # Set the UEFI resolution
    consoleMode = "keep";

  };

in
{

  # Unset the default console font
  console.font = "";

  # Main boot configuration
  boot = rec {

    # All the supported filesystems
    supportedFilesystems = [ "xfs" "zfs" "exfat" "ntfs" "btrfs" "autofs" "cifs" ];
    initrd.supportedFilesystems = supportedFilesystems;

    # Don't force import zfs pool
    zfs = {
      forceImportRoot = false;
      forceImportAll = false;
    };

    # Bootloader configuration
    loader = {

      # Set the given timeout
      timeout = my.config.boot.timeout;

    } //
    # Check if boot has been ovrriden
    (if my.config.boot.override then {} else (
      # Check which type of bootloader we are using
      if (my.config.boot.efi && (!my.config.boot.grub)) then
        { systemd-boot = systemDBootConfiguration; }
       else
        { grub = grubConfiguration; }
    ));

  };

}
