{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks."${networks.front.name}".external = true;

       #####
  ### # NUT # ###
       #####

  services."${names.nut}".service = {
    # Image
    image = "teknologist/webnut:latest";
    # Name
    container_name = names.nut;
    # Environment
    environment = {
      TZ = config.mine.system.timezone;
    };
    env_file = [ "/data/local/containers/nut/nut.env" ];
    # Networking
    networks = [ networks.front.name ];
  };

}