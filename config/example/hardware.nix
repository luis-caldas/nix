{ ... }:
{
  imports =
    [ <nixos/modules/installer/scan/not-detected.nix>
    ];

  boot.initrd.availableKernelModules = [ "ehci_hcd" "ahci" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-label/nixos";
      fsType = "ext3";
      options = [ "rw" "data=ordered" "relatime" ];
    };

  fileSystems."/boot" =
    { device = "/dev/sda1";
      fsType = "ext3";
      options = [ "rw" "errors=continue" "user_xattr" "acl" "barrier=1" "data=writeback" "relatime" ];
    };

  swapDevices =
    [ { device = "/dev/sda2"; }
    ];

  nix.maxJobs = 8;
}
