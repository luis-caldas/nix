{ lib, config, pkgs, ... }:
let

  # Common Names
  net = {
    bridges = {
      pool = "pool";
      stub = "stub";
      out = "out";
      ice = "ice";
    };
    vlans = {
      stan = {
        name = "stan"; id = 10;
      };
      service = {
        name = "service"; id = 20;
      };
    };
    ver = "ver";
    vrf = "upp";
    inter = {
      start = "100.100";
      mask = "30";
      host = "2";
      client = "1";
    };
  };

  # Number of networks to generate
  numberNetworks = 3;

in {

  # Kernel init
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" "kvmgt" "mdev" "vfio-iommu-type1" ];
  boot.extraModulePackages = [ ];

  # Show windows boot options
  boot.loader.systemd-boot.windows."11" = {
    title = "Windows";
    efiDeviceHandle = "HD1b";
  };

  # ZFS ask for password
  boot.zfs.requestEncryptionCredentials = true;

  # Monado
  services.monado.enable = true;
  services.monado.defaultRuntime = true;

  # My specific configuration
  mine = {
    services = {
      ssh = false;
      avahi = true;
      docker = true;
      printing = true;
      virtual = {
        enable = true;
        swtpm = true;
        android = true;
      };
    };
    graphics = {
      enable = true;
      cloud = true;
    };
    production = {
      audio = true;
      models = true;
      software = true;
      business = true;
      electronics = true;
    };
    audio = true;
    bluetooth = true;
    games = true;
  };

  ######################
  # === Networking === #
  ######################

  # Enable SystemD
  networking.networkmanager.enable = lib.mkForce false;

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

      # TODO Go over `networkctl` and set `RequiredForOnline`

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
        linkConfig.RequiredForOnline = "no";
      };

      # # VLAN
      # netdevs."10-${net.vlans.stan.name}" = {
      #   netdevConfig.Kind = "vlan";
      #   netdevConfig.Name = net.vlans.stan.name;
      #   vlanConfig.Id = net.vlans.stan.id;
      # };
      # networks."70-service" = {
      #   matchConfig.Name = net.vlans.stan.name;
      #   networkConfig.Bridge = net.bridges.pool;
      #   networkConfig.LinkLocalAddressing = "no";
      #   linkConfig.RequiredForOnline = "no";
      # };

      # Physical
      networks."50-wan" = {
        matchConfig.Name = "enp5s0";
        networkConfig.Bridge = net.bridges.pool;
        # networkConfig.Bridge = net.bridges.stub;
        # networkConfig.VLAN = net.vlans.stan.name;
        networkConfig.LinkLocalAddressing = "no";
        linkConfig.RequiredForOnline = "no";
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
        #
        networkConfig.DHCP = "ipv4";
        networkConfig.LinkLocalAddressing = "no";
        linkConfig.RequiredForOnline = "routable";
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
        networkConfig.LinkLocalAddressing = "no";
        networkConfig.VLAN = net.vlans.service.name;
        linkConfig.RequiredForOnline = "no";
      };

      # Physical
      networks."51-lan" = {
        matchConfig.Name = "enp6s0";
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
        networkConfig.DHCP = "ipv4";
        networkConfig.LinkLocalAddressing = "no";
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
      linkConfig.RequiredForOnline = "no";
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
      networkConfig.DHCPServer = "yes";
      dhcpServerConfig.ServerAddress = "${net.inter.start}.${number}.${net.inter.host}/${net.inter.mask}";
      dhcpServerConfig.Router = "${net.inter.start}.${number}.${net.inter.host}";
      dhcpServerConfig.PoolSize = 1;
      dhcpServerConfig.EmitDNS = "no";
      networkConfig.LinkLocalAddressing = "no";
      linkConfig.RequiredForOnline = "no";
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
      linkConfig.RequiredForOnline = "no";
    };
    networks."8${number}-${net.ver}-1" = {
      matchConfig.Name = "${net.ver}${number}1";
      networkConfig.VRF = "${net.vrf}${number}";
      networkConfig.DHCP = "ipv4";
      networkConfig.LinkLocalAddressing = "no";
      linkConfig.MACAddress = pkgs.functions.spoofMAC config.mine.system.hostname iteration pkgs.networks.mac.spoof;
      linkConfig.RequiredForOnline = "no";
      dhcpV4Config.SendHostname = "yes";
      dhcpV4Config.Hostname = pkgs.networks.hostname;
      dhcpV4Config.UseDNS = "no";
      dhcpV4Config.UseNTP = "no";
    };

  })
    (lib.lists.range 0 (numberNetworks - 1))
  ));

  ####################
  # NAT & Forwarding #
  ####################

  # NAT Firewall Rules
  systemd.services.natter = {
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
      iptables -w -t filter -A MINE_FORWARD -i ${net.ver}${number}1 -o ${net.bridges.out}${number} -m state --state RELATED,ESTABLISHED -j ACCEPT

      # <--- Out #

      # DMZ
      iptables -w -t nat -A MINE_PREROUTING -i ${net.ver}${number}1 -j DNAT --to-destination ${net.inter.start}.${number}.${net.inter.client}

    '')
      (lib.lists.range 0 (numberNetworks - 1))
    ));

  };

  # ===================================================== #

  # File systems

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/3FF1-6D0E";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  fileSystems."/" =
    { device = "knight/safe/root";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "knight/safe/home";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "knight/safe/nix";
      fsType = "zfs";
    };

  fileSystems."/tmp" =
    { device = "knight/safe/tmp";
      fsType = "zfs";
    };

  fileSystems."/data" =
    { device = "knight/safe/data";
      fsType = "zfs";
    };

  swapDevices = [
    {
      device = "/dev/disk/by-partuuid/3eeb2625-47cf-4282-a8c2-cc8de9e5f874";
      randomEncryption.enable = true;
    }
  ];

  # Governor and arch
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # State initialisation version
  system.stateVersion = "25.05";

}
