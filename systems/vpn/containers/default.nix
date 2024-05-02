{ pkgs, lib, config, ... }:
let

  # Shared information
  shared = {

    # Overall networking for docker
    networks = {

      wire = with pkgs.networks.docker.dns.vpn; {
        # Base
        name = "wire";
        inherit subnet gateway;
        # IPs
        ips = {
          # DNS
          dns = ips.main;
          dnsUp = ips.upstream;
        };
      };

      stun.name = "stun";

    };

    # Set up container names
    names = {
      dns = "dns";
      dnsUp = "dns-up";
      wire = "wire";
      stun = "stun";
    };

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

in {

  # Arion
  virtualisation.arion.projects = pkgs.functions.container.projects ./. shared;

  # Set the DNS
  networking.networkmanager.insertNameservers = [
    shared.networks.wire.ips.dns
  ] ++ pkgs.networks.dns;

}