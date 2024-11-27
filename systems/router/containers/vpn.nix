{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Set up the networks
  networks = pkgs.functions.container.populateNetworks [
    networks.vpn
  ];

       #########
  ### # OpenVPN # ###
       #########

  services."${names.vpn}".service = {

    # Image file
    image = "openvpn/openvpn-as:latest";

    # Volumes
    volumes = [
      "/data/local/containers/openvpn/config:/openvpn"
    ];

    # Networking
    ports = [
      "${builtins.toString pkgs.networks.ports.free}:${builtins.toString pkgs.networks.ports.free}/tcp"
      "${builtins.toString pkgs.networks.ports.open}:${builtins.toString pkgs.networks.ports.open}/udp"
    ];
    networks = [ networks.vpn ];
    capabilities.NET_ADMIN = true;

  };

}