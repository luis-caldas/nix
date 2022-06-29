{ my, lib, config, pkgs, ... }:
{

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "vfio-pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelParams = [ "pcie_aspm=off" "amd_iommu=on" "iommu=pt" "pci=noaer" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  boot.initrd.preDeviceCommands = ''
    devices="0000:07:00.0 0000:07:00.1"
    for each_device in $devices; do
      echo "vfio-pci" > /sys/bus/pci/devices/$each_device/driver_override
    done
    modprobe -i vfio-pci
  '';

  # Set up docker containers
  virtualisation.oci-containers.containers = {

    # Asterisk container
    asterisk = {
      image = "local/asterisk";
      imageFile = my.containers.asterisk;
      volumes = [
        "/data/local/docker/config/asterisk/conf:/etc/asterisk/conf.mine"
        "/data/local/docker/config/asterisk/voicemail:/var/spool/asterisk/voicemail"
        "/data/local/docker/config/asterisk/sounds:/usr/share/asterisk/sounds/mine"
      ];
      extraOptions = ["--dns=10.0.0.1"];
    };

    # DNS updater
    udns = {
      image = "local/udns";
      imageFile = my.containers.udns;
      environmentFiles = [ /data/local/safe/udns.env ];
    };

    # DNS Server
    adblock = {
      image = "pihole/pihole:latest";
      environment = {
        TZ = my.config.system.timezone;
        DNS1 = "1.1.1.1";
        DNS2 = "1.0.0.1";
      };
      environmentFiles = [ /data/local/safe/adblock.env ];
      volumes = [
        "/data/local/docker/config/pihole/etc:/etc/pihole"
        "/data/local/docker/config/pihole/dnsmasq:/etc/dnsmasq.d"
      ];
      ports = [
        "53:53/tcp"
        "53:53/udp"
        "80:80/tcp"
      ];
      extraOptions = ["--dns=127.0.0.1"];
    };

    # Shadow Socks server
    shadow = {
      image = "shadowsocks/shadowsocks-libev";
      environment = {
        METHOD = "aes-256-gcm";
        DNS_ADDRS = "10.0.0.1";
      };
      environmentFiles = [ /data/local/safe/shadow.env ];
      ports = [
        "8388:8388/tcp"
      ];
    };

  };

  fileSystems."/" =
    { device = "vimmer/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/B7F0-3A34";
      fsType = "vfat";
    };

  fileSystems."/home" =
    { device = "vimmer/home";
      fsType = "zfs";
    };

  fileSystems."/data/vms" =
    { device = "vimmer/vms";
      fsType = "zfs";
    };

  fileSystems."/data/local" =
    { device = "vimmer/data";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "vimmer/nix";
      fsType = "zfs";
    };

  fileSystems."/tmp" =
    { device = "vimmer/tmp";
      fsType = "zfs";
    };

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  system.stateVersion = "21.11";

}
