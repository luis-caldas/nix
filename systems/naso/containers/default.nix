{ pkgs, lib, config, ... }:
let

  # Shared information
  shared = {

    # Configure all the needed networks
    networks = {
      front.name = "front";
      search.name = "search";
      cloud.name = "cloud";
      share.name = "share";
    };

    # Keep track of all the names
    names = {
      # Front
      front = "proxy";
      # Share
      share = "samba";
      shout = "shout";
      # Download
      torrent = "torrent";
      aria = "aria";
      # Media
      jellyfin = "jellyfin";
      komga = "komga";
      # Social
      matrix = "matrix";
      # Search
      search = {
        app = "searx";
        redis = "search-redis";
      };
      # Cloud
      cloud = {
        app = "cloud";
        database = "cloud-maria";
        redis = "cloud-redis";
        proxy = "cloud-proxy";
        aio = "aio";
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
    front = [ "download" "media" "social" "search" "cloud" "vault" ];

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