{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks."${networks.front.name}".name = networks.front.name;

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
      "5000-5150:5000-5150/tcp"
      "5000-5150:5000-5150/udp"
    ];

    # Volumes
    volumes = [
      "/data/local/containers/track/app/traccar.xml:/opt/traccar/conf/traccar.xml:ro"
    ];

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
    env_file = [ "./mariadb.env" ];
    # Volumes
    volumes = [
      "/data/bunker/data/containers/track/database:/var/lib/mysql"
    ];
  };

}