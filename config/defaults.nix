{ lib, ... }:
{

  # My general configurations for the system
  options.my.config = {

    # The boot options be it MBR GRUB or EFI
    boot = {

      efi = mkOption {
        description = "Use EFI for boot";
        type = lib.types.bool;
        default = true;
      };

      grub = mkOption {
        description = "Use GRUB for boot, otherwise systemd-boot is used";
        type = lib.types.bool;
        default = false;
      };

      timeout = mkOption {
        description = "Timeout for the boot entry selection";
        type = lib.types.int;
        default = 60;
      };

      default = mkOption {
        description = "Default entry to be picked when using GRUB";
        type = lib.types.int;
        default = 0;
      };

      device = mkOption {
        description = "Device to install MBR GRUB onto";
        type = lib.types.str;
        default = "nodev";
      };

      prober = mkOption {
        description = "Probe the disks for OSs on GRUB";
        type = lib.type.bool;
        default = false;
      };

      tune = mkOption {
        description = "Play tune on GRUB";
        type = lib.type.bool;
        default = false;
      };

      top = mkOption {
        description = "Initilise `top` on TTY8";
        type = lib.type.bool;
        default = false;
      };

      override = mkOption {
        description = "Do not configure boot";
        type = lib.type.bool;
        default = false;
      };

    };

    # Kernel specific options
    kernel = {

      params = mkOptions {
        description = "Extra parameters for the kernel line on boot";
        type = lib.type.listOf lib.type.str;
        default = [];
      };

    };

  };

}