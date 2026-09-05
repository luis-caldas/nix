{ shared, lib, pkgs, config, ... }:

# Inherit the shared values
with shared;

let

  fullHostname = lib.strings.fileContents /data/local/containers/mail/hostname;
  domainName = let
    splitter = ".";
  in lib.strings.concatStringsSep splitter (
    lib.lists.drop 1 (lib.strings.splitString splitter fullHostname)
  );

  extraHostnames =
    lib.lists.filter (x: x != "")
      (lib.strings.splitString "\n" (
        lib.strings.fileContents /data/local/containers/mail/othernames
      ));

in {

  # Networking
  networks = pkgs.functions.container.populateNetworks
    (builtins.attrValues networks.mail);

       ######
  ### # Mail # ###
       ######

  services."${names.mail.app}".service = {

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

      # Rspamd stack
      ENABLE_RSPAMD = 1;
      ENABLE_CLAMAV = 1;
      ENABLE_FAIL2BAN = 1;

      # Disable the legacy filtering stack
      ENABLE_AMAVIS = 0;
      ENABLE_SPAMASSASSIN = 0;
      ENABLE_OPENDKIM = 0;
      ENABLE_OPENDMARC = 0;
      ENABLE_POLICYD_SPF = 0;
      ENABLE_POSTGREY = 0;

      # Accept spam, mark it and move to junk
      MOVE_SPAM_TO_JUNK = 1;
      MARK_SPAM_AS_READ = 1;
      RSPAMD_GREYLISTING = 0;

      # Limits
      POSTFIX_MESSAGE_SIZE_LIMIT = 102400000;

      # SSL
      SSL_TYPE = "manual";
      SSL_KEY_PATH = "/certificates/cert.key";
      SSL_CERT_PATH = "/certificates/cert.crt";

    };
    # RELAY_HOST
    # RELAY_PORT
    # RELAY_USER
    # RELAY_PASSWORD
    env_file = [ "/data/local/containers/mail/mail.env" ];

    # Networking
    ports = [
      "25:25"     # SMTP    S2S         Plaintext + STARTTLS
      #"110:110"  # POP3    Mailbox     Plaintext + STARTTLS
      "143:143"   # IMAP    Mailbox     Plaintext + STARTTLS
      "465:465"   # SMTPS               TLS
      "587:587"   # SMTP    Submission  STARTTLS
      "993:993"   # IMAPS               TLS
      #"995:995"  # POP3S               TLS
    ];

    # DNS
    dns = pkgs.networks.dns;

    # Capabilities
    capabilities = {
      NET_ADMIN = true;
    };

    # Volumes
    volumes = let
      virtualFix = pkgs.writeText "postfix-main.cf" ''
        virtual_mailbox_domains = ${domainName}, ${lib.strings.concatStringsSep ", " extraHostnames}
      '';
      rspamdActions = pkgs.writeText "rspamd-actions.conf" ''
        reject = null;
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
      # Rspamd configuration
      "${rspamdActions}:${configFolder}/rspamd/override.d/actions.conf:ro"
      # Locale
      "/etc/localtime:/etc/localtime:ro"
      # SSL
      "/data/local/containers/cert/ssl/mail:/certificates:ro"
    ];

    # Internal routing to web
    networks = {
      "${networks.mail.default}" = { aliases = [ fullHostname ]; };
    };

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
      ROUNDCUBEMAIL_UPLOAD_MAX_FILESIZE = "250M";
      # Domains
      ROUNDCUBEMAIL_DEFAULT_HOST = "ssl://${fullHostname}";
      ROUNDCUBEMAIL_SMTP_SERVER = "tls://${fullHostname}";
      #
      ROUNDCUBEMAIL_USERNAME_DOMAIN = domainName;
    };

    # Networking
    networks = [
      networks.mail.default
      networks.mail.web
    ];

  };

}