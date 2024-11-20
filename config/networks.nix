{ ... }:
let

  allNetworks = {

    # The normally allowed networks in my systems
    allowed = [
      "127.0.0.0/8"     # All the loopbacks
      "10.0.0.0/8"      # Classful network that I use
      "192.168.0.0/16"  # Another classful network
      "172.17.0.0/16"   # Docker subnet
    ];

    # All internal communication network
    internal = "10.255.0.0/16";

    # Alive the interval in seconds to keep alive
    alive = 5;

    # Main tunnel connections
    tunnel = {

      # Network itself
      network = "10.255.255.0";

      # Prefix of the network
      prefix = 24;

      # IPs of the network
      ips = {
        # Host
        host = "10.255.255.254";
        # Remote
        remote = "10.255.255.1";
        # VPN
        vpn = "10.255.255.10";
        # Mac
        macaco = "10.255.255.100";
      };

    };

    # VNP IP information
    vpn = {

      # Network itself
      network = "10.255.254.0";

      # Prefix of the network
      prefix = 24;

    };

    # Docker specific IPs
    docker = {

      # IPs needed for docker DNS configuration
      dns = {

        # Main DNS
        main = {
          # Network information
          subnet = "172.16.20.0/24"; gateway = "172.16.20.1";
          # IPs
          ips = {
            upstream = "172.16.20.10";
          };
        };

        # VPN DNS
        vpn = {

          # DNS
          dns = {
            # Network information
            subnet = "172.16.49.0/24"; gateway = "172.16.49.1";
            # IPs
            ips = {
              main = "172.16.49.11";
              upstream = "172.16.49.10";
            };
          };

          # Wire
          wire = {
            # Network information
            subnet = "172.16.50.0/24"; gateway = "172.16.50.1";
            # IPs
            ip = "172.16.50.10";
          };

        };

      };

      # NUT
      nut = {
        # Network information
        subnet = "172.16.30.0/24"; gateway = "172.16.30.1";
      };

    };

    # Internal use
    virtual = {
      # Address and prefix
      address = "172.25.0.1";
      prefix = 24;
    };

    # Ports
    ports = {

      # Original port of Wireguard
      wireguard = 51820;

      # Port (udp) most comonly used by VoIP providers (Zoom, Skype)
      # Therefore high change of not being blocked
      # Complete range is 3478 -> 3481
      # Port needs also be opened on hosting side
      open = 3478;

      # Simple port used for TURN
      turn = 37;

      # Simple UDP port used for wireguard
      simple = 123;

      # Start and end of registered ports
      start = 1024; end = 49151;

      # Normal
      https = 443;

    };

    # Mac addresses for devices
    mac = {

      # Routers virtual bridge
      firewall = "ff:54:ff:00:10:01";

      # VPNs mac for its virtual bridge
      vpn = "ff:54:ff:33:00:01";

    };

    # Main DNS servers
    dns = [
      "9.9.9.10"
      "149.112.112.10"
    ];

    # Time Providers
    time = "time.cloudflare.com";

  };

in {

  # Overlay
  nixpkgs.overlays = [

    # The overlay
    (final: prev: {

      # Add the networks
      networks = allNetworks;

    })

  ];

}