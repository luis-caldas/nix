{ lib, config, pkgs, ... }:
{

  # Kernel init
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # ZFS ask for password
  boot.zfs.requestEncryptionCredentials = true;

  # My specific configuration
  mine = {
    services = {
      ssh = true;
      avahi = true;
      docker = true;
      printing = true;
      virtual = {
        enable = true;
        swtpm = true;
      };
    };
  };

  ##############
  # Networking #
  ##############

  # Enable IP forwarding
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  boot.kernel.sysctl."net.ipv4.conf.all.forwarding" = 1;

  # Dont filter traffic through bridges
  boot.kernel.sysctl."net.bridge.bridge-nf-call-arptables" = 0;
  boot.kernel.sysctl."net.bridge.bridge-nf-call-iptables" = 0;
  boot.kernel.sysctl."net.bridge.bridge-nf-call-ip6tables" = 0;
  boot.kernel.sysctl."net.bridge.bridge-nf-filter-vlan-tagged" = 0;

  # Disable IPv6
  boot.kernel.sysctl."net.ipv6.conf.all.disable_ipv6" = 1;
  boot.kernel.sysctl."net.ipv6.conf.default.disable_ipv6" = 1;

  # Networling
  networking = {

    # Disable global DHCP
    useDHCP = false;

    # Use old dhcpcd
    dhcpcd = {

      # Disable bonjour
      extraConfig = ''
        noipv4ll
      '';

      # Replace the domain for a search
      runHook = ''
        sed 's/^domain/search/' -i /etc/resolv.conf
      '';

      # Don't hangup on startup
      wait = "background";

    };

    # Force disable Network Manager
    networkmanager.enable = lib.mkForce false;

    # Internal Bridge
    interfaces."lano" = {
      useDHCP = true;
      macAddress = "7a:f2:41:60:f0:01";
    };

    # Populate bridges
    bridges."lano".interfaces = [ "eno1" ];

    # Add another DNS to the DHCP acquired list
    # That is because the DNS server itself depends on this to start
    resolvconf = {
      enable = true;
      extraConfig = ''
        name_servers_append="${builtins.concatStringsSep " " pkgs.networks.dns}"
      '';
    };

  };

  # Virtualisation options
  virtualisation.libvirtd.onShutdown = "shutdown";

  # File systems

  # Boot

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/C310-CD09";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  fileSystems."/keys" =
    { device = "skib/safe/keys";
      fsType = "zfs";
      neededForBoot = true;
    };

  # System


  fileSystems."/" =
    { device = "skib/safe/system/root";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "skib/safe/system/home";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "skib/safe/system/nix";
      fsType = "zfs";
    };

  fileSystems."/tmp" =
    { device = "skib/safe/system/tmp";
      fsType = "zfs";
    };

  # Data

  fileSystems."/data/local" =
    { device = "skib/safe/data";
      fsType = "zfs";
    };

  fileSystems."/data/chung" =
    { device = "chungus/safe/data";
      fsType = "zfs";
    };

  # Swap

  swapDevices =
    [ { device = "/dev/disk/by-partuuid/b4b59e25-4a48-46fd-82cc-a9f3148351f3";
        randomEncryption.enable = true;
      }
    ];

  # Governor and arch
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # State initialisation version
  system.stateVersion = "24.11";

}