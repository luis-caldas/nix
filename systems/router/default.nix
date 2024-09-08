{ pkgs, lib, config, ... }: let

  # Shared information
  shared = {

    # Configure all the needed networks
    networks = pkgs.functions.container.createNames (let
      default = "default";
    in {
      simplifierIn = default;
      dataIn = {
        # Defaults
        "${default}" = [
          # Front
          "front"  # Should only be used for proxy
          # Asterisk
          "asterisk"
          # Home Assistant
          "home"
          # Nut
          "nut"
          # Dashboard
          "dash"
          # VPN
          "wire"
        ];
        # Base
        base = [ "dns" "hole" "time" ];
        # Monitor
        monitor = [ "grafana" "kuma" ];
      };
    });

    # Configure the needed names
    names =  pkgs.functions.container.createNames { dataIn = {
      # Non split containers
      app = [
        # Front
        "front"
        # Time
        "time"
        # Dashboard
        "dash"
        # UPS
        "nut"
        # Monitoring
        "monitor" "kuma"
        # Home Assistant
        "assistant"
        # VPN
        "wire"
      ];
      # DNS
      dns = [ "app" "up" ];
      # Asterisk
      asterisk = {
        app = [ "app" ];
        web = [ "simple" "normal" ];
      };
    };};

    # List of users for wireguard
    listUsers = let

      # Simple list that can be easily understood
      simpleList = [
        # Names will be changed for numbers starting on zero
        { home = [ "house" "router" "server" ]; }
        { lu = [ "laptop" "phone" "tablet" ]; }
        { m = [ "laptop" "phone" "extra" ]; }
        { lak = [ "laptop" "phone" "desktop" ]; }
        { extra = [ "first" "second" "third" "fourth" ]; }
      ];

      # Rename all users to
      arrayUsersDevices = map
        (eachEntry:
          builtins.concatLists (lib.attrsets.mapAttrsToList
          (eachUser: allDevices: map
            (eachDevice: "${eachUser}${pkgs.functions.capitaliseString eachDevice}")
            allDevices
          )
          eachEntry)
        )
        simpleList;

      # Join all the created lists
      interspersedUsers = lib.strings.concatStrings
        (lib.strings.intersperse "," (builtins.concatLists arrayUsersDevices));

    in interspersedUsers;

  };

  # Build the projects
  builtProjects = pkgs.functions.container.projects ./containers shared;

in {

  ########
  # Boot #
  ########

  # Modules for startup
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "vfio-pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelParams = [ "pcie_aspm=off" "amd_iommu=on" "iommu=pt" "pci=noaer" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  ########
  # VFIO #
  ########

  # VFIO overrides for VMs
  boot.initrd.preDeviceCommands = ''
    devices="0000:06:00.0 0000:06:00.1"
    for each_device in $devices; do
      echo "vfio-pci" > /sys/bus/pci/devices/$each_device/driver_override
    done
    modprobe -i vfio-pci
  '';

  #######
  # Own #
  #######

  # My own configuration
  mine = {
    minimal = true;
    system.hostname = "router";
    user.admin = false;
    services = {
      ssh = true;
      docker = true;
      virtual.enable = true;
      prometheus = {
        enable = true;
        password = "/data/local/prometheus/pass";
      };
    };
  };

  ##############
  # Networking #
  ##############

  # Enable IP forwarding
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  # Networling
  networking = {

    # Disable global DHCP
    useDHCP = false;

    # Disable bonjour
    dhcpcd.extraConfig = ''
      noipv4ll
    '';

    # Hangup on startup
    dhcpcd.wait = "background";

    # Force disable Network Manager
    networkmanager.enable = lib.mkForce false;

    # Per interface configuration
    interfaces = {
      enp5s0.useDHCP = true;
      firewall-bridge = {
        useDHCP = true;
        macAddress = pkgs.networks.mac.router;
      };
    };

    # Create the firewall bridge
    bridges.firewall-bridge.interfaces = [];

    # Add another DNS to the DHCP acquired list
    # That is because the DNS server itself depends on this to start
    resolvconf = {
      enable = true;
      extraConfig = ''
        name_servers_append="${builtins.concatStringsSep " " pkgs.networks.dns}"
      '';
    };

  };

  ##################
  # Virtualisation #
  ##################

  # Virtualisation options
  virtualisation.libvirtd.onShutdown = "shutdown";

  # Arion
  virtualisation.arion.projects = builtProjects;

  # Create all the needed dependencies
  systemd.services = pkgs.functions.container.createDependencies builtProjects;

  #######
  # UPS #
  #######

  # UPS configuration
  power.ups = {

    # Enable
    enable = true;
    mode = "netserver";

    # Device
    ups.apc = {
      port = "auto";
      driver = "usbhid-ups";
      description = "APC Smart 2200VA UPS";
      directives = lib.mapAttrsToList (name: value: "${name} = \"${value}\"") {
        vendorid = "051D";
        productid = "0002";
      };
    };

    # Service
    upsd = {
      enable = true;
      # Bind address
      listen = [ { address = "0.0.0.0"; } ];
    };

    # Users
    users.admin = {
      # UPS Monitor
      upsmon = "primary";
      # Password
      passwordFile = "/data/local/nut/pass";
    };

    # Monitor
    upsmon = {

      # Connection
      monitor.main = {
        system = "apc@localhost";
        powerValue = 1;
        user = "admin";
        passwordFile = "/data/local/nut/pass";
        type = "primary";
      };

      # Settings
      settings = pkgs.functions.ups.sharedConf // {

        # Scheduling Script
        NOTIFYCMD = "${pkgs.functions.ups.serverScript}";

        # Notify
        NOTIFYFLAG = pkgs.functions.ups.mapNotifyFlags [
          "ONLINE"   "ONBATT"  "LOWBATT"  "FSD"
          "COMMOK"   "COMMBAD" "SHUTDOWN"
          "REPLBATT" "NOCOMM"  "NOPARENT"
        ] pkgs.functions.ups.defaultNotify;

      };

    };

  };

  #########
  # Email #
  #########

  # Configure email sender
  programs.msmtp = {
    enable = true;
    setSendmail = true;
    defaults = {
      aliases = "/data/local/mail/alias";
      port = 465;
      tls_trust_file = "/etc/ssl/certs/ca-certificates.crt";
      tls = "on";
      auth = "login";
      tls_starttls = "off";
    };
    accounts = let
      mailDomain = lib.strings.fileContents /data/local/mail/domain;
      accountMail = lib.strings.fileContents /data/local/mail/account;
    in {
      default = {
        host = mailDomain;
        passwordeval = "${pkgs.coreutils}/bin/cat /data/local/mail/password";
        user = accountMail;
        from = accountMail;
      };
    };
  };

  ################
  # File Systems #
  ################

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

  swapDevices =
    [ { device = "/dev/disk/by-uuid/8306532e-4a62-4f99-b3df-7a7aa362958d"; }
    ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  system.stateVersion = "23.05";

}
