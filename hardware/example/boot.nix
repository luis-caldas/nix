{ lib, ... }:
{

  # Allow non free firmware
  hardware.enableRedistributableFirmware = lib.mkDefault true;

  # Boot configs for the proper loading of my disks
  boot = {

    # Load the proper modules and disks in the initrd
    initrd = {
      availableKernelModules = ["ahci" "usbhid" "usb_storage"];
      kernelModules = [];      
    };

    # Extra modules for the kernel
    kernelModules = [];
    extraModulePackages = [];

  };

}
