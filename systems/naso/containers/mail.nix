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

    extraHostnames = lib.strings.splitString "\n" (
      lib.strings.fileContents /data/local/containers/mail/othernames
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
        virtual_mailbox_domains = ${domainName}, ${lib.strings.concatStringsSep ", " extraHostnames}
      '';
      amavis = pkgs.writeText "amavis.cf" ''
        %final_destiny_by_ccat = (
          CC_VIRUS,      D_DISCARD,
          CC_SPAM,       D_DISCARD,
          CC_BANNED,     D_BOUNCE,
          CC_OVERSIZED,  D_BOUNCE,
          CC_BADH.',1',  D_PASS,    # BAD HEADER: MIME error
          CC_BADH.',2',  D_BOUNCE,  # BAD HEADER: nonencoded 8-bit character
          CC_BADH.',3',  D_BOUNCE,  # BAD HEADER: contains invalid control character
          CC_BADH.',4',  D_BOUNCE,  # BAD HEADER: line made up entirely of whitespace
          CC_BADH.',5',  D_BOUNCE,  # BAD HEADER: line longer than RFC 5322 limit
          CC_BADH.',6',  D_BOUNCE,  # BAD HEADER: syntax error
          CC_BADH.',7',  D_BOUNCE,  # BAD HEADER: missing required header field
          CC_BADH.',8',  D_PASS,    # BAD HEADER: duplicate header field
          CC_BADH,       D_PASS,    # BAD HEADER
          CC_UNCHECKED,  D_PASS,
          CC_CLEAN,      D_PASS,
          CC_CATCHALL,   D_PASS,
        );
      '';
      configFolder = "/tmp/docker-mailserver";
    in [
      # Config
      "/data/bunker/data/containers/mail/data/:/var/mail/"
      "/data/bunker/data/containers/mail/state/:/var/mail-state/"
      "/data/bunker/data/containers/mail/logs/:/var/log/mail/"
      "/data/bunker/data/containers/mail/config/:${configFolder}/"
      # Fix alias and relays
      "${virtualFix}:${configFolder}/postfix-main.cf:ro"
      # Amavis configuration
      "${amavis}:${configFolder}/amavis.cf:ro"
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