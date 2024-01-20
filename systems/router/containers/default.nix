{ pkgs, lib, config, ... }:
let

  # Shared information
  shared = {

    # Configure all the needed networks
    networks = {
      ### # Front # ###
      front.name = "front";
      ### # Time # ###
      time.name = "time";
      ### # DNS # ###
      dns = {
        name = "dns";
        subnet = "172.16.20.0/24"; gateway = "172.16.20.1";
        # IPs
        ips = {
          dns = "172.16.20.11";
          dnsUp = "172.16.20.10";
        };
      };
    };

    # Configure the needed names
    names = {
      # Front
      front = "front";
      # Base
      dns = "dns";
      dnsUp = "dns-up";
      time = "time";
      # Asterisk
      asterisk = {
        app = "asterisk";
        web = { simple = "asterisk-web-simple"; normal = "asterisk-web-normal"; };
      };
      # Monitor
      nut = "nut";
      # Web
      dash = "dash";
    };

  };

  # All the service dependencies
  dependencies = {

    # Services which depend on the front service
    # The names are equivalent to the file names
    front = [ "base" "asterisk" "nut" "web" ];

  };

in {

  # Arion
  virtualisation.arion.projects = pkgs.functions.container.projects ./. shared;

  # Create all the needed dependencies
  systemd.services = pkgs.functions.container.createDependencies dependencies;

}