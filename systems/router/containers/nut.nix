{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks."${networks.front}".external = true;

       #####
  ### # NUT # ###
       #####

  services."${names.nut}".service = {
    # Image
    image = "teknologist/webnut:latest";
    # Environment
    environment = {
      TZ = config.mine.system.timezone;
    };
    env_file = [ "/data/local/containers/nut/nut.env" ];
    # Networking
    networks = [ networks.front ];
  };

}