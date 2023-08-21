{ my, lib, config, modulesPath, pkgs, mfunc, ... }: let

  # Information for the wireguard and NAT networking
  networkInfo = {
    host = "10.1.0.1";
    remote = "10.1.0.2";
    prefix = 16;
    port = 123;
    external = "enp1s0";
    interface = "wg0";
  };

in {

  # Needed for virutalisation
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  # Boot information
  boot.loader.grub.device = "/dev/sda";
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "xen_blkfront" ];
  boot.initrd.kernelModules = [ "nvme" ];

  # DNS servers
  networking.networkmanager.insertNameservers = [ "9.9.9.10" "149.112.112.10" ];

  # Disable all ipv6
  networking.enableIPv6 = false;

  # Some kernel configs
  boot.kernel.sysctl."net.ipv6.conf.all.disable_ipv6" = 1;
  boot.kernel.sysctl."net.ipv6.conf.default.disable_ipv6" = 1;
  boot.kernel.sysctl."net.ipv4.conf.all.src_valid_mark" = 1;

  # Firewall setup
  networking.firewall = {
    enable = lib.mkForce true;
    allowedTCPPorts = [
      22    # SSH port
      124
    ];
    allowedUDPPorts = [
      123   # Port chosen for the VPN
      124
    ];
  };
  # Setup Fail 2 Ban
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    ignoreIP = [
      "127.0.0.0/8"         # Local subnet
      "10.0.0.0/8"          # Local subnet
      "192.168.0.0/16"      # Local subnet
      "172.17.0.0/16"       # Docker subnet
    ];
  };

  # Disable avahi
  services.avahi.enable = lib.mkForce false;

  # SSH setup
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = lib.mkForce "no";
      KbdInteractiveAuthentication = false;
      PasswordAuthentication = false;
    };
  };
  # User keys for ssh
  users.users."${my.config.user.name}".openssh.authorizedKeys.keyFiles = [
    /etc/nixos/ssh/authorized_keys
  ];
  users.users.lakituen = {
    isNormalUser  = true;
    home = "/home/lakituen";
    openssh.authorizedKeys.keyFiles = [
      /etc/nixos/ssh/extra
    ];
  };

  # Set up our NAT configuration
  networking.nat = {
    enable = true;
    externalInterface = networkInfo.external;
    internalInterfaces = [ networkInfo.interface ];
    dmzHost = networkInfo.remote;
    forwardPorts = [
      { destination = "${networkInfo.host}:22"; proto = "tcp"; sourcePort = 22; }
      { destination = "${networkInfo.host}:${builtins.toString networkInfo.port}"; proto = "udp"; sourcePort = networkInfo.port; }
      { destination = "${networkInfo.host}:${builtins.toString (networkInfo.port + 1)}"; proto = "tcp"; sourcePort = networkInfo.port + 1; }
      { destination = "${networkInfo.host}:${builtins.toString (networkInfo.port + 1)}"; proto = "udp"; sourcePort = networkInfo.port + 1; }
    ];
  };

  # Set up our wireguard configuration
  networking.wireguard.interfaces."${networkInfo.interface}" = {
    ips = [ "${networkInfo.host}/${builtins.toString networkInfo.prefix}" ];
    listenPort = networkInfo.port;
    privateKeyFile = "/data/local/wire/host.key";
    peers = [{
      publicKey = mfunc.safeReadFile /data/local/wire/remote.pub;
      allowedIPs = [ "${networkInfo.remote}/32" ];
    }];
  };

  # Wireguard containarised
#  virtualisation.oci-containers.containers = {
#    wireguard = let
#      DEFAULT_PORT = builtins.toString 51820;
#      NEW_PORT = builtins.toString 69;
#      allUsers = [
#        # Names will be changed for numbers starting on zero
#        { home = [ "house" "router" "server" ]; }
#        { lu = [ "laptop" "phone" "tablet" ]; }
#        { lak = [ "laptop" "phone" "desktop" ]; }
#        { extra = [ "first" "second" "third" "fourth" ]; }
#      ];
#      allPeers = let
#        arrayUsersDevices = map
#          (eachEntry:
#            builtins.concatLists (lib.attrsets.mapAttrsToList
#            (eachUser: allDevices: lib.lists.imap0
#              (index: eachDevice: "${eachUser}${builtins.toString index}")
#              allDevices
#            )
#            eachEntry)
#          )
#          allUsers;
#        usersDevicesList = builtins.concatLists arrayUsersDevices;
#        interspersedList = lib.strings.intersperse "," usersDevicesList;
#      in lib.strings.concatStrings interspersedList;
#    in {
#      image = "lscr.io/linuxserver/wireguard:latest";
#      environment = {
#        TZ = my.config.system.timezone;
#        PUID = builtins.toString my.config.user.uid;
#        GUID = builtins.toString my.config.user.gid;
#        INTERNAL_SUBNET = "192.168.100.1";
#        PEERS = allPeers;
#        SERVERURL = "auto";
#        SERVERPORT = "${NEW_PORT}";
#        PEERDNS = "auto";
#      };
#      volumes = [
#        "/data/local/wireguard:/config"
#      ];
#      ports = [
#        "${NEW_PORT}:${DEFAULT_PORT}/udp"
#      ];
#      extraOptions = [ "--cap-add=NET_ADMIN" ];
#    };
#  };

  # File systems and SWAP
  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };
  swapDevices = [ {
    device = "/swapfile";
    size = (1024 * 4); # Size in MB
  } ];

  system.stateVersion = "23.05";

}
