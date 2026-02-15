{ ... }:
let

  allNetworks = {

    # Hostname
    hostname = "MyRouter";

    # VNP IP information
    vpn = {

      # Network itself
      network = "10.255.254.0";

      # Prefix of the network
      prefix = 24;

    };

    # Ports
    ports = {

      # Original port of Wireguard
      wireguard = 51820;

      # Port (UDP) most commonly used by VoIP providers (Zoom, Skype)
      # Therefore high change of not being blocked
      # Complete range is 3478 -> 3481
      # Port needs also be opened on hosting side
      open = 3478;

      # Port (TCP) where traffic is most likely to work
      free = 143;

      # Simple port used for TURN
      turn = 37;

      # Simple UDP used
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

      # Spoof
      spoof = "3c:58:5d:00:00:00";

    };

    # Main DNS servers
    dns = [
      "9.9.9.10"
      "149.112.112.10"
    ];

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