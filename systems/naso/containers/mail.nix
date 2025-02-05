{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks = pkgs.functions.container.populateNetworks [
    networks.mail
  ];

       ######
  ### # Mail # ###
       ######

  services."${names.mail}".service = {

    # Image
    image = "ghcr.io/docker-mailserver/docker-mailserver:latest";

    # Hostname
    hostname = lib.strings.fileContents /data/local/containers/mail/hostname;

    # Name
    container_name = names.mail;

    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      # Security
      SPOOF_PROTECTION = 1;
      ENABLE_RSPAMD = 1;
      ENABLE_CLAMAV = 1;
      ENABLE_FAIL2BAN = 1;
      # SSL
      SSL_TYPE = "manual";
      SSL_KEY_PATH = "/ssl/main.key";
      SSL_CERT_PATH = "/ssl/main.crt";
    };
    # RELAY_HOST
    # RELAY_PORT
    # RELAY_USER
    # RELAY_PASSWORD
    env_file = [ "/data/local/containers/mail/mail.env" ];

    # Networking
    ports = [
      "25:25"
      "465:465"
      "587:587"
      "993:993"
    ];

    # Capabilities
    capabilities = {
      NET_ADMIN = true;
    };

    # Volumes
    volumes = [
      "/data/bunker/data/containers/mail/data/:/var/mail/"
      "/data/bunker/data/containers/mail/state/:/var/mail-state/"
      "/data/bunker/data/containers/mail/logs/:/var/log/mail/"
      "/data/bunker/data/containers/mail/config/:/tmp/docker-mailserver/"
      # Locale
      "/etc/localtime:/etc/localtime:ro"
      # SSL
      "/data/local/containers/mail/ssl:/ssl:ro"
    ];

    # No internal networking needed

  };

}