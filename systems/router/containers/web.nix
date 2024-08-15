{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks = pkgs.functions.container.populateNetworks [
    networks.dash
  ];

       ######
  ### # Dash # ###
       ######

  services."${names.dash}" = {
    # Image
    build.image = lib.mkForce (pkgs.containers.web { name = "dashboard"; url = "https://github.com/luis-caldas/personal"; });
    # Options
    service = {
      # Volumes
      volumes = [
        "/data/local/containers/dash/config:/web/more:ro"
      ];
      # Networking
      networks = [ networks.dash ];
    };
  };

}