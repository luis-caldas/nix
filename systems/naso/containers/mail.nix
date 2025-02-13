{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

{

  # Networking
  networks = pkgs.functions.container.populateNetworks
    (builtins.attrValues networks.mail);

       ######
  ### # Mail # ###
       ######

  services."${names.mail.app}".service = let

    fullHostname = lib.strings.fileContents /data/local/containers/mail/hostname;
    domainName = let
      splitter = ".";
    in lib.strings.concatStringsSep splitter (
      lib.lists.drop 1 (lib.strings.splitString splitter fullHostname)
    );

  in {

    # Image
    image = "ghcr.io/docker-mailserver/docker-mailserver:latest";

    # Hostname
    hostname = fullHostname;

    # Name
    container_name = names.mail.app;

    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      # Security
      SPOOF_PROTECTION = 1;
      ENABLE_RSPAMD = 1;
      ENABLE_CLAMAV = 1;
      ENABLE_FAIL2BAN = 1;
      # Limits
      POSTFIX_MESSAGE_SIZE_LIMIT = 102400000;
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
      "143:143"
      "465:465"
      "587:587"
      "993:993"
    ];

    # Capabilities
    capabilities = {
      NET_ADMIN = true;
    };

    # Volumes
    volumes = let
      virtualFix = pkgs.writeText "postfix-main.cf" ''
        virtual_mailbox_domains = ${domainName}
      '';
    in [
      # Config
      "/data/bunker/data/containers/mail/data/:/var/mail/"
      "/data/bunker/data/containers/mail/state/:/var/mail-state/"
      "/data/bunker/data/containers/mail/logs/:/var/log/mail/"
      "/data/bunker/data/containers/mail/config/:/tmp/docker-mailserver/"
      # Fix alias and relays
      "${virtualFix}:/tmp/docker-mailserver/postfix-main.cf:ro"
      # Locale
      "/etc/localtime:/etc/localtime:ro"
      # SSL
      "/data/local/containers/mail/ssl:/ssl:ro"
    ];

    # No internal networking needed

  };

       ###########
  ### # Interface # ###
       ###########

  services."${names.mail.web}".service = {

    # Image
    image = "roundcube/roundcubemail:latest";

    # Name
    container_name = names.mail.web;

    # Environment
    environment = pkgs.functions.container.fixEnvironment {
      # Settings
      ROUNDCUBEMAIL_DEFAULT_PORT = 993;
      ROUNDCUBEMAIL_SMTP_PORT = 587;
      ROUNDCUBEMAIL_UPLOAD_MAX_FILESIZE = "100M";
    };
    env_file = [ "/data/local/containers/mail/web.env" ];

    # Networking
    networks = [ networks.mail.web ];

  };

}