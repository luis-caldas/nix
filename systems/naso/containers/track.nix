{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks."${networks.front}".external = true;
  networks."${networks.track}".name = networks.track;

       #########
  ### # Traccar # ###
       #########

  services."${names.track.app}".service = {

    # Image
    image = "traccar/traccar:latest";

    # Internal hostname
    hostname = names.track.app;

    # Name
    container_name = names.track.app;

    # Depends
    depends_on = [ names.track.database ];

    # Ports
    ports = [
      # Sinotrack
      "5013:5013/tcp"
      "5013:5013/udp"
      # Smartphones
      "5055:5055/tcp"
      "5055:5055/udp"
    ];

    # Volumes
    volumes = [
      "/data/local/containers/track/app/traccar.xml:/opt/traccar/conf/traccar.xml:ro"
    ];

    # Networking
    networks = [ networks.track networks.front ];

  };

       ##########
  ### # Database # ###
       ##########

  services."${names.track.database}".service = {
    # Image
    image = "mariadb:latest";
    # Name
    container_name = names.track.database;
    # Environment
    environment = {
      TZ = config.mine.system.timezone;
      MARIADB_DATABASE = names.track.app;
      MARIADB_USER = names.track.app;
    };
    env_file = [ "/data/local/containers/track/database.env" ];
    # Volumes
    volumes = [
      "/data/bunker/data/containers/track/database:/var/lib/mysql"
    ];
    # Networking
    networks = [ networks.track ];
  };

}