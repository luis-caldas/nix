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
      dns = with pkgs.networks.docker.dns.main; {
        name = "dns";
        inherit subnet gateway;
        # IPs
        ips = {
          dns = ips.main;
          dnsUp = ips.upstream;
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
      # Monitor
      monitor = "monitor";
    };

  };

  # All the service dependencies
  dependencies = {

    # Services which depend on the front service
    # The names are equivalent to the file names
    front = [ "base" "asterisk" "nut" "web" "monitor" ];

  };

in {

  # Arion
  virtualisation.arion.projects = pkgs.functions.container.projects ./. shared;

  # Create all the needed dependencies
  systemd.services = pkgs.functions.container.createDependencies dependencies;

}