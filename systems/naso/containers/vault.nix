{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks = pkgs.functions.container.populateNetworks [
    networks.vault
  ];

       #######
  ### # Vault # ###
       #######

  services."${names.vault}".service = {
    # Image
    image = "vaultwarden/server:latest";
    # Environment
    environment = {
      TZ = config.mine.system.timezone;
      SIGNUPS_ALLOWED = "false";
    };
    env_file = [ "/data/local/containers/warden/warden.env" ];
    # Volumes
    volumes = [
      "/data/bunker/data/containers/warden:/data"
    ];
    # Networking
    networks = [ networks.vault ];
  };

}