{ lib, ... }:
{

  # Allow non free firmware
  hardware.enableRedistributableFirmware = lib.mkDefault true;

  # Boot configs for the proper loading of my disks
  boot = {

    # Load the proper modules and disks in the initrd
    initrd = {
      availableKernelModules = ["nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "vfio-pci"];
      kernelModules = [];
    };

    kernelParams = [ "pcie_aspm=off" "amd_iommu=on" ];

    #initrd.preDeviceCommands = ''
    #  devices="0000:0a:00.0 0000:0a:00.1"
    #  for each_device in $devices; do
    #    echo "vfio-pci" > /sys/bus/pci/devices/$each_device/driver_override
    #  done
    #  modprobe -i vfio-pci
    #'';

    # Extra modules for the kernel
    kernelModules = ["kvm-amd"];
    extraModulePackages = [];

  };

  # Set the proper number of the max jobs
  nix.maxJobs = lib.mkDefault 16;
  powerManagement.cpuFreqGovernor = lib.mkDefault "schedutil";

  # Tell the system that this luks device exists
  boot.initrd.luks.devices."nixor".device = "/dev/disk/by-uuid/2afde2a8-0d37-4fa5-a20d-c63ef994381f";

  # General disk mounting
  fileSystems."/" = {
    device = "kwool/root";
    fsType = "zfs";
  };

  fileSystems."/home" = {
    device = "kwool/home";
    fsType = "zfs";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/D649-527B";
    fsType = "vfat";
  };

  fileSystems."/strongo" = {
    device = "/dev/disk/by-label/Strongo";
    fsType = "btrfs";
  };

  # I don't really need swap on this system
  swapDevices = [];

}
