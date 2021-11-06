{ lib, ... }:
{

  # Boot configs for the proper loading of my disks
  boot = {

    # Load the proper modules and disks in the initrd
    initrd = {
      availableKernelModules = ["nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "vfio-pci"];
      kernelModules = [];
    };

    kernelParams = [ "pcie_aspm=off" "amd_iommu=on" "iommu=pt" "pci=noaer" "amdgpu.dc=0" "video=vesafb:off,efifb:off" "nofb" ];

    initrd.preDeviceCommands = ''
      devices="0000:09:00.0 0000:09:00.1 0000:05:00.0"
      for each_device in $devices; do
        echo "vfio-pci" > /sys/bus/pci/devices/$each_device/driver_override
      done
      modprobe -i vfio-pci
    '';

    # Extra modules for the kernel
    kernelModules = ["kvm-amd"];
    extraModulePackages = [];

  };

  # Set the proper number of the max jobs
  powerManagement.cpuFreqGovernor = lib.mkDefault "schedutil";

 }
