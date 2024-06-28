{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks."${networks.front}".external = true;

       ######
  ### # Dash # ###
       ######

  services."${names.dash}" = {
    # Image
    build.image = lib.mkForce (pkgs.containers.web { name = "dashboard"; url = "https://github.com/luis-caldas/personal"; });
    # Options
    service = {
      # Name
      container_name = names.dash;
      # Volumes
      volumes = [
        "/data/local/containers/dash/config:/web/more:ro"
      ];
      # Networking
      networks = [ networks.front ];
    };
  };

}