{ pkgs, lib, config, ... }:
let

  # Shared information
  shared = {

    # Configure all the needed networks
    networks = {
      front.name = "front";
      track.name = "track";
      workout.name = "workout";
      recipe.name = "recipe";
      cloud.name = "cloud";
      git.name = "git";
      share.name = "share";
      social.name = "social";
    };

    # Keep track of all the names
    names = {
      # Front
      front = "proxy";
      access = "proxy-access";
      # Share
      share = "samba";
      shout = "shout";
      # Track
      track = {
        app = "track";
        database = "track-database";
      };
      # Workout
      wger = {
        wger = "wger";
        cache = "wger-cache";
        database = "wger-database";
        web = "wger-web";
        worker = "wger-celery-worker";
        beat = "wger-celery-beat";
        flower = "wger-celery-flower";
      };
      # Recipe
      tandoor = {
        app = "tandoor";
        database = "tandoor-database";
      };
      # Download
      torrent = "torrent";
      aria = "aria";
      # Media
      jellyfin = "jellyfin";
      komga = "komga";
      browser = "browser";
      shower = "shower";
      gitea = {
        app = "gitea";
        db = "gitea-database";
      };
      # Social
      matrix = {
        app = "matrix";
        database = "matrix-database";
        admin = "matrix-admin";
        bridge = {
          whats = "bridge-whats";
          disc = "bridge-discord";
          gram = "bridge-telegram";
          slac = "bridge-slack";
          sig = "bridge-signal";
          meta = "bridge-meta";
          sms = "bridge-sms";
          db = {
            whats = "bridge-db-whats";
            disc = "bridge-db-discord";
            gram = "bridge-db-telegram";
            slac = "bridge-db-slack";
            sig = "bridge-db-signal";
            meta = "bridge-db-meta";
            sms = "bridge-db-sms";
          };
        };
      };
      # Cloud
      cloud = {
        app = "cloud";
        database = "cloud-maria";
        redis = "cloud-redis";
        proxy = "cloud-proxy";
        cron = "cloud-cron";
      };
      # Vault
      vault = "vault";
    };

    # Predefined ports
    ports.https = "443";

  };

  # All the service dependencies
  dependencies = {

    # Services which depend on the front service
    # The names are equivalent to the file names
    front = [ "download" "media" "social" "cloud" "vault" "track" "workout" "git" "recipe" ];

  };

in {

  # Arion
  virtualisation.arion.projects = pkgs.functions.container.projects ./. shared;

  # Create all the needed dependencies
  systemd.services = pkgs.functions.container.createDependencies dependencies;

  # Publish Avahi
  # Which is needed to advertise the network share
  services.avahi = {
    enable = true;
    nssmdns = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
    extraServiceFiles.smb = ''
      <?xml version="1.0" standalone='no'?><!--*-nxml-*-->
      <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
      <service-group>
        <name replace-wildcards="yes">%h</name>
        <service>
          <type>_smb._tcp</type>
          <port>445</port>
        </service>
      </service-group>
    '';
  };

}