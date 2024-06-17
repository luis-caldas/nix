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
      # Home Assistant
      assistant = "assistant";
      kuma = "kuma";
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

  # Build the projects
  builtProjects = pkgs.functions.container.projects ./. shared;

in {

  # Arion
  virtualisation.arion.projects = builtProjects;

  # Create all the needed dependencies
  systemd.services = pkgs.functions.container.createDependencies (
    pkgs.functions.container.extractDependencies builtProjects
  );

}