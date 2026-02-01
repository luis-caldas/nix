{ pkgs, lib, config, ... }: let

  # Common Names
  net = {
    # Interfaces
    one = "enp5s0";
    ten = {
      outside = "enp6s0f0";
      inside = "enp6s0f1";
    };
    # Bridges
    bridges = {
      pool = "pool";
      stub = "stub";
      out = "out";
      ice = "ice";
      fire = "fire";
    };
    # VLANs
    vlans = {
      stan = {
        name = "stan"; id = 10;
      };
      service = {
        name = "service"; id = 20;
      };
    };
    # Names
    ver = "ver";
    vrf = "upp";
    # IPs
    inter = {
      start = "100.100";
      mask = "30";
      host = "2";
      client = "1";
    };
  };

  # Number of networks to generate
  numberNetworks = 3;

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

  ######################
  # === Networking === #
  ######################

  # Enable SystemD
  networking.networkmanager.enable = lib.mkForce false;

  # BUG https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=165059

  # Forwarding
  boot.kernel.sysctl = {
    # Forwarding
    "net.ipv4.ip_forward" = 1;
    # Disable Bridge Filtering
    "net.bridge.bridge-nf-call-arptables" = 0;
    "net.bridge.bridge-nf-call-iptables" = 0;
    "net.bridge.bridge-nf-call-ip6tables" = 0;
    "net.bridge.bridge-nf-filter-vlan-tagged" = 0;
    # Disable IPv6
    "net.ipv6.conf.all.disable_ipv6" = 1;
    "net.ipv6.conf.default.disable_ipv6" = 1;
  };

  # Config Layout #

  # 0X - Virtual Devices - Bridges
  # 1X - Virtual Devices - VLANs
  # 3X - Virtual Devices - VRFs
  # 4X - Virtual Devices - VEth

  # 5X - Networks - Real Devices

  # 6X - Networks - Bridges
  # 7X - Networks - VLANs
  # 8X - Networks - VRFs
  # 9X - Networks - VEths

  # Main Settings
  systemd.network = lib.mkMerge ([

    {

      # Enable
      enable = true;

      ########
      # Stub #
      ########

      # Bridge
      netdevs."00-${net.bridges.stub}" = {
        netdevConfig.Kind = "bridge";
        netdevConfig.Name = net.bridges.stub;
      };
      networks."60-${net.bridges.stub}" = {
        matchConfig.Name = net.bridges.stub;
        networkConfig.LinkLocalAddressing = "no";
        linkConfig.RequiredForOnline = "carrier";
      };

      # VLAN
      netdevs."10-${net.vlans.stan.name}" = {
        netdevConfig.Kind = "vlan";
        netdevConfig.Name = net.vlans.stan.name;
        vlanConfig.Id = net.vlans.stan.id;
      };
      networks."70-service" = {
        matchConfig.Name = net.vlans.stan.name;
        networkConfig.Bridge = net.bridges.pool;
        networkConfig.LinkLocalAddressing = "no";
        linkConfig.RequiredForOnline = "enslaved";
      };

      # Physical
      networks."50-wan" = {
        matchConfig.Name = net.ten.outside;
        networkConfig.Bridge = net.bridges.stub;
        networkConfig.VLAN = net.vlans.stan.name;
        networkConfig.LinkLocalAddressing = "no";
        linkConfig.RequiredForOnline = "enslaved";
      };

      ########
      # Pool #
      ########

      # Bridge
      netdevs."01-${net.bridges.pool}" = {
        netdevConfig.Kind = "bridge";
        netdevConfig.Name = net.bridges.pool;
      };
      networks."61-${net.bridges.pool}" = {
        matchConfig.Name = net.bridges.pool;
        networkConfig.LinkLocalAddressing = "no";
        linkConfig.RequiredForOnline = "carrier";
      };

      #######
      # Ice #
      #######

      # Bridge
      netdevs."02-${net.bridges.ice}" = {
        netdevConfig.Kind = "bridge";
        netdevConfig.Name = net.bridges.ice;
      };
      networks."62-${net.bridges.ice}" = {
        matchConfig.Name = net.bridges.ice;
        # networkConfig.DHCP = "ipv4";
        # dhcpV4Config.RouteMetric = 8192;
        networkConfig.VLAN = net.vlans.service.name;
        networkConfig.LinkLocalAddressing = "no";
        linkConfig.RequiredForOnline = "carrier";
      };

      # Physical
      networks."51-lan" = {
        matchConfig.Name = net.ten.inside;
        networkConfig.Bridge = net.bridges.ice;
        linkConfig.RequiredForOnline = "enslaved";
      };

      # VLAN
      netdevs."11-${net.vlans.service.name}" = {
        netdevConfig.Kind = "vlan";
        netdevConfig.Name = net.vlans.service.name;
        vlanConfig.Id = net.vlans.service.id;
      };
      networks."71-service" = {
        matchConfig.Name = net.vlans.service.name;
        networkConfig.Bridge = net.bridges.fire;
        networkConfig.LinkLocalAddressing = "no";
        linkConfig.RequiredForOnline = "enslaved";
      };

      ########
      # Fire #
      ########

      # Bridge
      netdevs."03-${net.bridges.fire}" = {
        netdevConfig.Kind = "bridge";
        netdevConfig.Name = net.bridges.fire;
      };
      networks."63-${net.bridges.fire}" = {
        matchConfig.Name = net.bridges.fire;
        networkConfig.DHCP = "ipv4";
        networkConfig.LinkLocalAddressing = "no";
        linkConfig.RequiredForOnline = "carrier";
      };

      #########
      # Maint #
      #########

      # Physical
      networks."52-maint" = {
        matchConfig.Name = net.one;
        networkConfig.DHCP = "ipv4";
        networkConfig.LinkLocalAddressing = "no";
        dhcpV4Config.RouteMetric = 16384;
        linkConfig.RequiredForOnline = "no";
      };

    }

  ] ++

  # ---

  (map (iteration: let
    number = builtins.toString iteration;
    bridgeOffset = builtins.toString (iteration + 4);
  in {

    ########
    # VRFs #
    ########

    netdevs."3${number}-${net.vrf}" = {
      netdevConfig.Kind = "vrf";
      netdevConfig.Name = "${net.vrf}${number}";
      vrfConfig.Table = 100 + iteration;
    };
    networks."8${number}-${net.vrf}" = {
      matchConfig.Name = "${net.vrf}${number}";
      networkConfig.LinkLocalAddressing = "no";
      linkConfig.RequiredForOnline = "carrier";
    };

    ##############
    # Out Bridge #
    ##############

    # Bridge
    netdevs."0${bridgeOffset}-${net.bridges.out}" = {
      netdevConfig.Kind = "bridge";
      netdevConfig.Name = "${net.bridges.out}${number}";
    };
    networks."6${bridgeOffset}-${net.bridges.out}" = {
      matchConfig.Name = "${net.bridges.out}${number}";
      networkConfig.VRF = "${net.vrf}${number}";
      networkConfig.Address = "${net.inter.start}.${number}.${net.inter.host}/${net.inter.mask}";
      networkConfig.LinkLocalAddressing = "no";
      linkConfig.RequiredForOnline = "routable";
    };

    ####################
    # Virtual Ethernet #
    ####################

    # Connects Input Bridge to VRF

    # Device
    netdevs."3${number}-${net.ver}" = {
      netdevConfig.Kind = "veth";
      netdevConfig.Name = "${net.ver}${number}0";
      peerConfig.Name = "${net.ver}${number}1";
    };
    networks."8${number}-${net.ver}-0" = {
      matchConfig.Name = "${net.ver}${number}0";
      networkConfig.Bridge = net.bridges.pool;
      networkConfig.LinkLocalAddressing = "no";
      linkConfig.RequiredForOnline = "enslaved";
    };
    networks."8${number}-${net.ver}-1" = {
      matchConfig.Name = "${net.ver}${number}1";
      networkConfig.VRF = "${net.vrf}${number}";
      networkConfig.DHCP = "ipv4";
      networkConfig.LinkLocalAddressing = "no";
      dhcpV4Config.SendHostname = "yes";
      dhcpV4Config.Hostname = pkgs.networks.hostname;
      dhcpV4Config.UseDNS = "no";
      dhcpV4Config.UseNTP = "no";
      linkConfig.MACAddress = pkgs.functions.spoofMAC config.mine.system.hostname iteration pkgs.networks.mac.spoof;
      linkConfig.RequiredForOnline = "routable";
    };

  })
    (lib.lists.range 0 (numberNetworks - 1))
  ));

  # ===================================================== #

  ##################
  # Virtualisation #
  ##################

  # Virtualisation options
  virtualisation.libvirtd.onShutdown = "shutdown";

  # Arion
  virtualisation.arion.projects = builtProjects;

  # Create all the needed dependencies
  systemd.services =
    (pkgs.functions.container.createDependencies builtProjects)
    //

  ####################
  # NAT & Forwarding #
  ####################

  {
    natter = {
      description = "Network Address Translation";
      wantedBy = [ "network.target" ];
      after = [
        "network-pre.target"
        "systemd-modules-load.service"
      ];
      path = [ config.networking.firewall.package ];
      unitConfig.ConditionCapability = "CAP_NET_ADMIN";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      # Script
      script = ''

        # == Filter == #

        iptables -w -t filter -N MINE_FORWARD
        iptables -w -t filter -I FORWARD 1 -j MINE_FORWARD

        # == NAT == #

        iptables -w -t nat -N MINE_PREROUTING
        iptables -w -t nat -N MINE_POSTROUTING

        iptables -w -t nat -I PREROUTING 1 -j MINE_PREROUTING
        iptables -w -t nat -I POSTROUTING 1 -j MINE_POSTROUTING

        # == Speed == #
        iptables -w -t filter -A MINE_FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT

      '' + (lib.strings.concatStrings (map (iteration: let
        number = builtins.toString iteration;
      in ''

        # -- X -- #

        iptables -w -t filter -A INPUT -i ${net.ver}${number}1 -j DROP
        iptables -w -t filter -A MINE_FORWARD -i ${net.ver}${number}1 -j DROP

        # ---> In #

        # Masquerade
        iptables -w -t nat -A MINE_POSTROUTING -o ${net.ver}${number}1 -j MASQUERADE

        # Outgoing & Established Reply
        iptables -w -t filter -A MINE_FORWARD -i ${net.bridges.out}${number} -o ${net.ver}${number}1 -j ACCEPT

        # <--- Out #

        # DMZ
        iptables -w -t nat -A MINE_PREROUTING -i ${net.ver}${number}1 -j DNAT --to-destination ${net.inter.start}.${number}.${net.inter.client}

      '')
        (lib.lists.range 0 (numberNetworks - 1))
      ));

    };

  };

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
