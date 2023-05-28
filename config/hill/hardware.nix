{ my, lib, config, ... }:
{

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelParams = [ ];
  boot.kernelModules = [ "kvm-amd" "kvmgt" "mdev" "vfio-iommu-type1" ];
  boot.extraModulePackages = [ ];

  boot.zfs.requestEncryptionCredentials = true;

  # Create all the services needed for the containers networks
  systemd.services = let
    # Names of networks and their subnets
    networks = {
      pbx = "172.16.72.0/24";
    };
  in
    my.containers.functions.addNetworks networks;

  # Set up docker containers
  virtualisation.oci-containers.containers = let
    givenName = "maria";
  in {

    # Database
    maria = {
      image = "mariadb:latest";
      environment = {
        TZ = my.config.system.timezone;
        MARIADB_DATABASE = givenName;
        MARIADB_USER = givenName;
        MARIADB_ROOT_PASSWORD = builtins.hashString "md5" givenName;
        MARIADB_PASSWORD = builtins.hashString "md5" givenName;
      };
      volumes = [
        "/home/lu/home/downloads/temp/maria:/var/lib/mysql"
      ];
      extraOptions = [ "--network=pbx" "--ip=172.16.72.100" ];
    };

    pbx = {
      image = "tiredofit/freepbx:latest";
      dependsOn = [ "maria" ];
      environment = my.containers.functions.fixEnv {
        HTTP_PORT = 80;

        RTP_START = 18000;
        RTP_FINISH = 20000;

        DB_EMBEDDED = "FALSE";
        ENABLE_FAIL2BAN = "FALSE";

        DB_HOST = "172.16.72.100";
        DB_PORT = 3306;
        DB_NAME = givenName;
        DB_USER = givenName;
        DB_PASS = builtins.hashString "md5" givenName;
      };
      volumes = [
          "/home/lu/home/downloads/temp/pbx/certs:/certs"
          "/home/lu/home/downloads/temp/pbx/data:/data"
          "/home/lu/home/downloads/temp/pbx/logs:/var/log"
          "/home/lu/home/downloads/temp/pbx/data/www:/var/www/html"
      ];
      ports = [
        "80:80/tcp"
        "5060:5060/udp"
        "5160:5160/udp"
        "18000-20000:18000-20000/udp"
      ];
      extraOptions = [ "--network=pbx" "--ip=172.16.72.150" ];
    };

  };

  fileSystems."/" =
    { device = "hill/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/669A-8E94";
      fsType = "vfat";
    };

  fileSystems."/nix" =
    { device = "hill/nix";
      fsType = "zfs";
    };

  fileSystems."/tmp" =
    { device = "hill/tmp";
      fsType = "zfs";
    };

  # Second disk
  fileSystems."/safe" =
    { device = "hill/safe";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "mound/home";
      fsType = "zfs";
      depends = [ "/safe" ];
    };

  fileSystems."/data" =
    { device = "mound/safe";
      fsType = "zfs";
      depends = [ "/safe" ];
    };

  fileSystems."/store" =
    { device = "mound/store";
      fsType = "zfs";
      depends = [ "/safe" ];
    };

  swapDevices = [ ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

}
