{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks = pkgs.functions.container.populateNetworks [
    networks.nut
  ];

       #####
  ### # NUT # ###
       #####

  services."${names.nut}".service = {
    # Image
    image = "edgd1er/webnut:latest";
    # Environment
    environment = {
      TZ = config.mine.system.timezone;
    };
    env_file = [ "/data/local/containers/nut/nut.env" ];
    # Networking
    networks = [ networks.nut ];
  };

}