{ pkgs, lib, config, ... }:
{

  virtualisation.arion = let

    ############
    # Networks #
    ############

    # Configure all the needed networks
    networks = {

      ### # Front # ###
      front = { name = "front"; subnet = "172.16.10.0/24"; gateway = "172.16.100.1"; };

      ### # SearX # ###
      search = { name = "search"; subnet = "172.16.20.0/24"; gateway = "172.16.250.1"; };

      ### # Cloud # ###
      cloud = { name = "cloud"; subnet = "172.16.50.0/24"; gateway = "172.16.200.1"; };

      ### # Share # ###
      share = { name = "share"; subnet = "172.16.30.0/24"; gateway = "172.16.50.1"; };

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
      };

      # Vault
      vault = "vault";

    };

    # Predefined ports
    ports.https = "8443";

  in {

    #########
    # Front #
    #########

    # All services that will serve the front

    projects.front.settings = {

      # Networking
      networks."${networks.front.name}" = {
        name = networks.front.name;
        ipam.config = [{ inherit (networks.front) subnet gateway; }];
      };

      ### # Proxy # ###

      services."${names.front}".service = {
        # Image
        image = "jc21/nginx-proxy-manager:latest";
        # Name
        container_name = names.front;
        # Volumes
        volumes = [
          "/data/local/containers/proxy:/data"
        ];
        # Networking
        ports = [
          "80:80/tcp"
          "443:443/tcp"
          "81:81/tcp"
        ];
        # Networking
        networks = [ networks.front.name ];
      };

    };

    #########
    # Share #
    #########

    # Sharing services and needed components
    projects.share.settings = {

      ### # SAMBA # ###

      services."${names.share}".service = {

        # Image
        image = "dperson/samba:latest";

        # Name
        container_name = names.share;

        # Environment
        environment = pkgs.containerFunctions.fixEnvironment {
          TZ = config.mine.system.timezone;
          USERID = config.mine.user.uid;
          GROUPID = config.mine.user.gid;
        };
        env_file = [ "/data/local/containers/media/samba.env" ];

        # Volumes
        volumes = [
          "/data/storr/media:/media"
          "/data/local/containers/media/ps2:/ps2"
          "/data/storr/media/games/roms/ps2/dvd:/ps2/DVD:ro"
          "/data/storr/media/games/roms/ps2/cd:/ps2/CD:ro"
          "/data/storr/media/games/roms/ps2/art:/ps2/ART:ro"
        ];

        # Networking
        ports = [
          "137:137/udp"
          "138:138/udp"
          "139:139/tcp"
          "445:445/tcp"
        ];

        # Command
        command = lib.strings.concatStringsSep " " ([
          "-g" "log level = 2" # Global config
          "-n" # NMBF
          "-r" # Remove recycle bin
          "-S" # Disable minimum SMB2
          "-s" "media;/media;yes;no;no;all;;;Share for media files" # Share config
          "-s" "ps2;/ps2;yes;no;yes;all;;;PS2 Games"
          "-w" "WORKGROUP" # Default workgroup
          "-W" # Wide link support
        ]);

        # Networking
        networks = [ networks.share.name ];

      };

      ### # Shout # ###

      services."${names.shout}".service = {
        # Image
        image = "aovestdipaperino/wsdd2";
        # Name
        container_name = names.shout;
        # Environment
        environment = {
          TZ = config.mine.system.timezone;
          HOSTNAME = config.mine.system.hostname;
        };
        # Networking
        network_mode = "host";  # Multicast support
      };

    };

    ############
    # Download #
    ############

    # Services used to download things

    projects.download.settings = {

      # Networking
      networks."${networks.front.name}".external = true;

      ### # Torrent # ###

      services."${names.torrent}".service = {
        # Image
        image = "lscr.io/linuxserver/qbittorrent:latest";
        # Name
        container_name = names.torrent;
        # Environment
        environment = pkgs.containerFunctions.fixEnvironment {
          TZ = config.mine.system.timezone;
          PUID = config.mine.user.uid;
          PGID = config.mine.user.gid;
          WEBUI_PORT = 8080;
        };
        # Volumes
        volumes = [
          "/data/local/containers/torrent:/config"
          "/data/storr/media/downloads:/downloads"
        ];
        # Networking
        networks = [ networks.front.name ];
      };

      ### # Aria # ###

      services."${names.aria}".service = {
        # Image
        image = "hurlenko/aria2-ariang:latest";
        # Name
        container_name = names.aria;
        # Environment
        environment = pkgs.containerFunctions.fixEnvironment {
          PUID = config.mine.user.uid;
          PGID = config.mine.user.gid;
          ARIA2RPCPORT = networks.ports.https;
        };
        # Volumes
        volumes = [
          "/data/local/containers/aria:/aria2/conf"
          "/data/storr/media/downloads:/aria2/data"
        ];
        # Networking
        networks = [ networks.front.name ];
        # Service doesn't gracefully shut down, it may need tini
      };

    };

    #########
    # Media #
    #########

    # All the media content

    projects.media.settings = {

      # Networking
      networks."${networks.front.name}".external = true;

      ### # Jellyfin # ###

      services."${names.jellyfin}".service = let

        # Names of the folders that will be synced
        syncFolders = [ "anime" "cartoons" "films" "series" ];

      in {

        # Image
        image = "lscr.io/linuxserver/jellyfin:latest";

        # Name
        container_name = names.jellyfin;

        # Environment
        environment = pkgs.containerFunctions.fixEnvironment {
          TZ = config.mine.system.timezone;
          PUID = config.mine.user.uid;
          PGID = config.mine.user.gid;
        };

        # Volumes
        volumes = [
          "/data/local/containers/jellyfin:/config"
        ] ++
        # Extra folders mapping
        (map (eachFolder: "/data/storr/media/${eachFolder}:/data/${eachFolder}:ro") syncFolders);

        # Networking
        networks = [ networks.front.name ];

      };

      ### # Komga # ###

      services."${names.komga}".service = {
        # Image
        image = "gotson/komga:latest";
        # Name
        container_name = names.komga;
        # Environment
        environment = {
          TZ = config.mine.system.timezone;
        };
        # User information
        user = "${builtins.toString config.mine.user.uid}";
        # Volumes
        volumes = [
          "/data/local/containers/komga:/config"
          "/data/storr/media/manga:/data:ro"
        ];
        # Networking
        networks = [ networks.front.name ];
      };

    };

    ##########
    # Social #
    ##########

    # TODO Create configuration for container

    # Social networks and messaging

    projects.social.settings = {

      # Networking
      networks."${networks.front.name}".external = true;

      ### # Matrix # ###

      services."${names.matrix}".service = {
        # Image
        image = "matrixdotorg/synapse:latest";
        # Name
        container_name = names.matrix;
        # Environment
        environment = pkgs.containerFunctions.fixEnvironment {
          TZ = config.mine.system.timezone;
          UID = config.mine.user.uid;
          GID = config.mine.user.gid;
        };
        # Volumes
        volumes = [
          "/data/bunker/data/containers/matrix:/data"
        ];
        # Networking
        networks = [ networks.front.name ];
      };

    };

    ##########
    # Search #
    ##########

    # TODO Create needed directories

    # Search engine

    projects.search.settings = {

      # Networking
      networks."${networks.front.name}".external = true;
      networks."${networks.search.name}" = {
        name = networks.search.name;
        ipam.config = [{ inherit (networks.search) subnet gateway; }];
      };

      ### # SearXNG # ###

      services."${names.search.app}".service = {
        # Image
        image = "searxng/searxng:latest";
        # Name
        container_name = names.search.app;
        # Depends
        depends_on = [ names.search.redis ];
        # Environment
        environment = [];
        env_file = [ "/data/local/containers/search/searx.env" ];
        # Volumes
        volumes = [
          "/data/bunker/data/containers/search/application:/etc/searxng:rw"
        ];
        # Networking
        networks = [ networks.search.name networks.front.name ];
      };

      ### # Redis # ###

      services."${names.search.redis}".service = {
        # Image
        image = "redis:latest";
        # Name
        container_name = names.search.redis;
        # Environment
        environment = {
          TZ = config.mine.system.timezone;
        };
        # Volumes
        volumes = [
          "/data/bunker/data/containers/search/redis:/data"
        ];
        # Command
        command = "--save 60 1";
        # Networking
        networks = [ networks.search.name ];
      };

    };

    #########
    # Cloud #
    #########

    # All the cloud applications

    projects.cloud.settings = let

      # Database configuration
      db = rec {
        name = "cloud";
        user = name;
      };

    in {

      # Networking
      networks."${networks.front.name}".external = true;
      networks."${networks.cloud.name}" = {
        name = networks.cloud.name;
        ipam.config = [{ inherit (networks.cloud) subnet gateway; }];
      };

      ### # Application # ###

      services."${names.cloud.app}".service = {
        # Image
        image = "nextcloud:latest";
        # Name
        container_name = names.cloud.app;
        # Dependend
        depends_on = [ names.cloud.database names.cloud.redis ];
        # Environment
        environment = {
          TZ = config.mine.system.timezone;
          # Mariadb
          MYSQL_HOST = names.cloud.database;
          MYSQL_DATABASE = db.name;
          MYSQL_USER = db.user;
          # Redis
          REDIS_HOST = names.cloud.redis;
          # Data
          NEXTCLOUD_DATA_DIR = "/data";
        };
        env_file = [ "/data/local/containers/cloud/cloud.env" ];
        # Volumes
        volumes = [
          "/data/bunker/data/containers/cloud/application:/var/www/html"
          "/data/bunker/cloud/cloud:/data"
        ];
        # Networking
        network = [ networks.cloud.name networks.front.name ];
      };

      ### # Database # ###

      services."${names.cloud.database}".service = {
        # Image
        image = "mariadb:latest";
        # Name
        container_name = names.cloud.database;
        # Environment
        environment = {
          TZ = config.mine.system.timezone;
          MARIADB_DATABASE = db.name;
          MARIADB_USER = db.user;
        };
        env_file = [ "/data/local/containers/cloud/mariadb.env" ];
        # Volumes
        volumes = [
          "/data/bunker/data/containers/cloud/mariadb:/var/lib/mysql"
        ];
        # Networking
        networks = [ networks.cloud.name ];
      };

      ### # Redis # ###

      services."${names.cloud.redis}".service = {
        # Image
        image = "redis:latest";
        # Name
        container_name = names.cloud.redis;
        # Environment
        environment = {
          TZ = config.mine.system.timezone;
        };
        # Volumes
        volumes = [
          "/data/bunker/data/containers/cloud/redis:/data"
        ];
        # Command
        command = "--save 60 1";
        # Networking
        networks = [ networks.cloud.name ];
      };

      ### # Proxy # ###

      services."${names.cloud.proxy}".service = let

        # Create the proxy configuration attr set for this container
        proxyConfiguration = pkgs.containerFunctions.createProxy {
          net = {
            ip = networks.cloud.ips.cloud;
            port = "80";
          };
          port = "9443";
          ssl = {
            key = "/data/local/containers/cloud/ssl/main.key";
            cert = "/data/local/containers/cloud/ssl/main.pem";
          };
          extraConfig = ''
              client_max_body_size 512M;
              client_body_timeout 300s;
              fastcgi_buffers 64 4K;
              location /.well-known/carddav {
                  return 301 $scheme://$host:$server_port/remote.php/dav;
              }
              location /.well-known/caldav {
                  return 301 $scheme://$host:$server_port/remote.php/dav;
              }
          '';
        };

      in {
        # Name
        container_name = names.cloud.proxy;
        # Networking
        networks = [ networks.cloud.name ];
      } //
      # Add the proxy configuration
      # It contains the image ports and volumes needed
      proxyConfiguration;

    };

    #########
    # Vault #
    #########

    # My vault application

    projects.vault.settings = {

      # Networking
      networks."${networks.front.name}".external = true;

      ### # Vault # ###

      services."${names.vault}".service = {
        # Image
        image = "vaultwarden/server:latest";
        # Name
        container_name = names.vault;
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
        networks = [ networks.front.name ];
      };

    };

  };

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