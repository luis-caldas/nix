{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks."${networks.front.name}".external = true;

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
        "/data/local/containers/dash/config/other.json:/web/other.json:ro"
      ];
      # Networking
      networks = [ networks.front.name ];
    };
  };

}