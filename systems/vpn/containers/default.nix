{ pkgs, lib, config, ... }@args:
let

  # Shared information
  shared = {

    # All the wireguard info
    wireguard = {

      # Subnet for Wireguard
      subnet = "10.255.254.0/24";

      # Subnet for all internal communications
      internal = "10.255.0.0/16";

      # Original Wireguard port
      original = 51820;

      # Port (udp) most comonly used by VoIP providers (Zoom, Skype)
      # Therefore high change of not being blocked
      # Complete range is 3478 -> 3481
      # Port needs also be opened on hosting side
      container = 3478;

    };

    # Overall networking for docker
    networks = {

      wire = {
        # Base
        name = "wire";
        subnet = "172.16.50.0/24"; gateway = "172.16.50.1";
        # IPs
        ips = {
          # DNS
          dns = "172.16.50.11";
          dnsUp = "172.16.50.10";
        };
      };

    };

    # Set up container names
    names = {
      dns = "dns";
      dnsUp = "dns-up";
      wire = "wire";
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
  virtualisation.arion.projects = let

    # All the possible imports
    extension = "nix";
    possible = pkgs.functions.listFileNamesExtensionExcluded ./. [ "default" ] extension;

  in builtins.listToAttrs (

    # Map all the files to new format
    map (each: {

      # Name of
      name = each;

      # The set
      value = {

        # Set the service name also
        serviceName = each;

        # Import the settings from specific file
        settings = import ("${each}.${extension}") (args // { inherit shared; });

      };

    }) possible

  );

}