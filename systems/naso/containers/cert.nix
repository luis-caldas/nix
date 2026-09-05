{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks = pkgs.functions.container.populateNetworks [
    networks.cert
  ];

       ##############
  ### # Certificates # ###
       ##############

  services."${names.cert}".service = {

    # Image
    image = "certimate/certimate:latest";

    # DNS
    dns = pkgs.networks.dns;

    # Volumes
    volumes = [
      # Application data
      "/data/local/containers/cert/application:/app/pb_data"

      # Certificates
      "/data/local/containers/cert/ssl:/certificates"

      # Locale
      "/etc/localtime:/etc/localtime:ro"
    ];

    # Networking
    networks = [
      networks.cert
    ];

  };

}