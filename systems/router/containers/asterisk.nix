{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks."${networks.front}".external = true;

       ##########
  ### # Asterisk # ###
       ##########

  services."${names.asterisk.app}" = {
    # Image
    build.image = lib.mkForce pkgs.containers.asterisk;
    # Configuration
    service = {
      # Name
      container_name = names.asterisk.app;
      # Volumes
      volumes = [
        "/data/local/containers/asterisk/config/conf:/etc/asterisk/conf.mine"
        "/data/local/containers/asterisk/config/voicemail:/var/spool/asterisk/voicemail"
        "/data/local/containers/asterisk/config/record:/var/spool/asterisk/monitor"
        "/data/local/containers/asterisk/config/sounds:/var/lib/asterisk/sounds/mine"
        # Email files
        "/data/local/mail:/data/local/mail:ro"
        "/etc/msmtprc:/etc/msmtprc:ro"
      ];
      # Networking
      network_mode = "host";
    };
  };

       ##############
  ### # Asterisk Web # ###
       ##############

  services."${names.asterisk.web.normal}" = {
    # Image
    build.image = lib.mkForce (pkgs.containers.web {});
    # Options
    service = {
      # Name
      container_name = names.asterisk.web.normal;
      # Volumes
      volumes = [
        "/data/local/containers/asterisk/config/voicemail:/web/voicemail:ro"
        "/data/local/containers/asterisk/config/record:/web/monitor:ro"
      ];
      # Networking
      networks = [ networks.front ];
    };
  };

       #####################
  ### # Asterisk Web Simple # ###
       #####################

  services."${names.asterisk.web.simple}".service = {
    # Image
    image = "halverneus/static-file-server:latest";
    # Name
    container_name = names.asterisk.web.simple;
    # Volumes
    volumes = [
      "/data/local/containers/asterisk/config/voicemail:/web/voicemail:ro"
      "/data/local/containers/asterisk/config/record:/web/monitor:ro"
    ];
    # Networking
    networks = [ networks.front ];
  };

}