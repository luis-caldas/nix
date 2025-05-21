{ pkgs, lib, config, ... }: let

  # Interfaces informaion
  interfaces = {
    one = "enp5s0";
    ten = {
      outside = "enp6s0f0";
      inside = "enp6s0f1";
    };
    bridges = {
      fire = "firewall-bridge";
      ice  = "icewall-bridge";
      virt = "virtuall-bridge";
      pon  = "pon-bridge";
    };
    stub = "stub";
    upper = {
      one   = "upper-one";
      two   = "upper-two";
      three = "upper-three";
      four  = "upper-four";
    };
  };

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
          # Manage
          "manage"
          # Asterisk
          "asterisk"
          # Home Assistant
          "home"
          # Dashboard
          "dash"
          # VPN
          "vpn"
        ];
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
        # Portainer
        "portainer"
        # Time
        "time"
        # Dashboard
        "dash"
        # Monitoring
        "monitor" "kuma"
        # Home Assistant
        "assistant"
        # VPN
        "vpn"
      ];
      # Asterisk
      asterisk = {
        app = [ "app" ];
        web = [ "simple" "normal" ];
      };
    };};

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

  # Encryption
  boot.zfs.requestEncryptionCredentials = true;

  #######
  # Own #
  #######

  # My own configuration
  mine = {
    minimal = true;
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

    # VLANs
    vlans = {
      # Stub
      "${interfaces.stub}" = { id = 10; interface = interfaces.ten.outside; };
    };

    # Default Gigabit & Management Network
    interfaces."${interfaces.one}".useDHCP = true;

    # Stub
    interfaces.stub.useDHCP = false;

    # Internal Bridge
    interfaces."${interfaces.bridges.virt}" = {
      useDHCP = true;
      macAddress = pkgs.networks.mac.firewall;
    };
    # Firewall Bridge
    interfaces."${interfaces.bridges.fire}".useDHCP = false;
    # Pon Bridge
    interfaces."${interfaces.bridges.pon}".useDHCP = false;
    # Icewall Bridge
    interfaces."${interfaces.bridges.ice}".useDHCP = false;

    # Upper Interfaces
    interfaces."${interfaces.upper.one}".useDHCP = false;
    interfaces."${interfaces.upper.two}".useDHCP = false;
    interfaces."${interfaces.upper.three}".useDHCP = false;
    interfaces."${interfaces.upper.four}".useDHCP = false;

    # Populate bridges
    bridges."${interfaces.bridges.virt}".interfaces = [];
    bridges."${interfaces.bridges.fire}".interfaces = [ interfaces.ten.inside ];
    bridges."${interfaces.bridges.pon}".interfaces = [ interfaces.ten.outside ];
    bridges."${interfaces.bridges.ice}".interfaces = [ interfaces.stub ];

    # Populate the upper interfaces
    bridges."${interfaces.upper.one}".interfaces = [];
    bridges."${interfaces.upper.two}".interfaces = [];
    bridges."${interfaces.upper.three}".interfaces = [];
    bridges."${interfaces.upper.four}".interfaces = [];

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

    # Maintenance
    users.maintenance = {
      instcmds = [ "ALL" ];
      actions = [ "set" "fsd" ];
      # Password
      passwordFile = "/data/local/nut/maintenance_pass";
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

  # Boot

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/B7F0-3A34";
      fsType = "vfat";
    };

  # System

  fileSystems."/" =
    { device = "vimmer/safe/system/root";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "vimmer/safe/system/home";
      fsType = "zfs";
    };

  fileSystems."/data/vm" =
    { device = "vimmer/safe/system/vm";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "vimmer/safe/system/nix";
      fsType = "zfs";
    };

  fileSystems."/tmp" =
    { device = "vimmer/safe/system/tmp";
      fsType = "zfs";
    };

  # Data

  fileSystems."/data/local" =
    { device = "vimmer/safe/data";
      fsType = "zfs";
    };

  # SWAP

  swapDevices =
    [ {
        device = "/dev/disk/by-partuuid/63383757-a754-4c79-9754-5d4d8feab235";
        randomEncryption.enable = true;
      }
    ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  system.stateVersion = "23.05";

}
