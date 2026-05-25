{ pkgs, lib, config, ... }:

let

  # GRUB configuration
  grubConfiguration = {

    # Basic
    enable = true;

    # ZFS fixes
    copyKernels = true;

    # Try to identify other systems
    useOSProber = config.mine.boot.prober;

    # Enable Memtest
    memtest86.enable = true;

    # EFI support
    efiInstallAsRemovable = config.mine.boot.efi;
    efiSupport = config.mine.boot.efi;

    # ZFS support
    zfsSupport = true;

    # Force real text modes
    gfxpayloadBios = "text";
    gfxpayloadEfi = "text";

    # Set GRUB to console mode
    extraConfig = "
      terminal_input console
      terminal_output console
    " +
    # Add a custom tune to the start if set
    (if config.mine.boot.tune then "play 600 440 1 220 1 880 1 0 1 880 2" else "");

    # Default GRUB entry
    default = config.mine.boot.default;

    # Eye candy
    splashImage = null;

    # Specify the devices
    devices = config.mine.boot.devices;

  };

  # systemd boot configuration
  systemDBootConfiguration = {

    # Enable systemd boot and disable command line editing
    enable = if config.mine.boot.secure then (lib.mkForce false) else true;
    editor = false;

    # Set the UEFI resolution
    consoleMode = "keep";

    # Extra entries
    memtest86.enable = true;
    netbootxyz.enable = true;
    edk2-uefi-shell.enable = true;

  };

in {

  # Unset the default console font
  console.font = "";

  # Main boot configuration
  boot = rec {

    # All supported file systems
    supportedFilesystems = [ "xfs" "zfs" "exfat" "ext4" "ntfs" "btrfs" "autofs" "cifs" ];
    initrd.supportedFilesystems = supportedFilesystems;

    # Don't force import the ZFS pool
    zfs = {
      forceImportRoot = false;
      forceImportAll = false;
    };

    # Check whether boot must be overwritten
    loader = if config.mine.boot.override then (lib.mkForce {}) else ({

      # Set the given timeout
      timeout = config.mine.boot.timeout;

    } //
    # Check which bootloader is being used
    (if (config.mine.boot.efi && (!config.mine.boot.grub)) then
      { systemd-boot = systemDBootConfiguration; }
    else
      { grub = grubConfiguration; }
    ));

    lanzaboote = lib.mkIf (config.mine.boot.secure) {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };

  };

}
