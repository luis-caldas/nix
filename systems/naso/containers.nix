{ pkgs, lib, config, ... }:
{

  virtualisation.arion = let

    ############
    # Networks #
    ############

    # Configure all the needed networks
    networks = {

      ### # Front # ###

      front = {
        # Main
        name = "front";
        subnet = "172.16.100.0/24"; gateway = "172.16.100.1";
        # IPs
        ips = {
          jellyfin = "172.16.100.10";
          komga = "172.16.100.20";
          torrent = "172.16.100.50";
          aria = "172.16.100.60";
          matrix = "172.16.100.100";
          search = "172.16.100.150";
          cloud = "172.16.100.200";
          vault = "172.16.100.250";
        };
      };

      ### # SearX # ###

      search = {
        # Main
        name = "search";
        subnet = "172.16.250.0/24"; gateway = "172.16.250.1";
        # IPs
        ips = {
          redis = "172.16.250.10";
        };
      };

      ### # Cloud # ###

      cloud = {
        # Main
        name = "cloud";
        subnet = "172.16.200.0/24"; gateway = "172.16.200.1";
        # IPs
        ips = {
          database = "172.16.200.10";
          redis = "172.16.200.20";
          cloud = "172.16.200.5";
        };
      };

      ### # Share # ###
      share = { name = "share"; subnet = "172.16.50.0/24"; gateway = "172.16.50.1"; };

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

      services.proxy.service = {
        # Image
        image = "jc21/nginx-proxy-manager:latest";
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

      services.samba.service = {

        # Image
        image = "dperson/samba:latest";

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

      services.shout.service = {
        # Image
        image = "aovestdipaperino/wsdd2";
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

    projects.share.settings = {

      # Networking
      networks."${networks.front.name}".external = true;

      ### # Torrent # ###

      services.torrent.service = {
        # Image
        image = "lscr.io/linuxserver/qbittorrent:latest";
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
        networks."${networks.front.name}".ipv4_address = networks.front.ips.torrent;
      };

      ### # Aria # ###

      services.aria.service = {
        # Image
        image = "hurlenko/aria2-ariang:latest";
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
        networks."${networks.front.name}".ipv4_address = networks.front.ips.aria;
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

      services.jellyfin.service = let

        # Names of the folders that will be synced
        syncFolders = [ "anime" "cartoons" "films" "series" ];

      in {

        # Image
        image = "lscr.io/linuxserver/jellyfin:latest";

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

        # Needed ports
        ports = [
          "7359:7359/udp"
          "1900:1900/udp"
        ];

        # Networking
        networks."${networks.front.name}".ipv4_address = networks.front.ips.jellyfin;

      };

      ### # Komga # ###

      services.komga.service = {
        # Image
        image = "gotson/komga:latest";
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
        networks."${networks.front.name}".ipv4_address = networks.front.ips.komga;
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

      services.matrix.service = {
        # Image
        image = "matrixdotorg/synapse:latest";
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
        networks."${networks.front.name}".ipv4_address = networks.front.ips.matrix;
      };

    };

    ##########
    # Search #
    ##########

    # TODO Create needed directories

    # Search engine

    projects.search.settings = let

      # Commonly used names
      names.redis = "searx-redis";

    in {

      # Networking
      networks."${networks.front.name}".external = true;
      networks."${networks.search.name}" = {
        name = networks.search.name;
        ipam.config = [{ inherit (networks.search) subnet gateway; }];
      };

      ### # SearXNG # ###

      services.searx.service = {
        # Image
        image = "searxng/searxng:latest";
        # Depends
        depends_on = [ names.redis ];
        # Environment
        environment = [];
        env_file = [ "/data/local/containers/search/searx.env" ];
        # Volumes
        volumes = [
          "/data/bunker/data/containers/search/application:/etc/searxng:rw"
        ];
        # Networking
        networks."${networks.search.name}" = {};
        networks."${networks.front.name}".ipv4_address = networks.front.ips.search;
      };

      ### # Redis # ###

      services."${redisSearch}".service = {
        # Image
        image = "redis:latest";
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
        networks."${networks.search.name}".ipv4_address = networks.search.ips.redis;
      };

    };

    #########
    # Cloud #
    #########

    # All the cloud applications

    project.cloud.settings = let

      # Commonly used names
      names = {
        database = "cloud-maria";
        redis = "cloud-redis";
        proxy = "cloud-proxy";
      };

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

      services.cloud.service = {
        # Image
        image = "nextcloud:latest";
        # Dependend
        depends_on = [ names.database names.redis ];
        # Environment
        environment = {
          TZ = config.mine.system.timezone;
          # Mariadb
          MYSQL_HOST = networks.cloud.ip.database;
          MYSQL_DATABASE = db.name;
          MYSQL_USER = db.user;
          # Redis
          REDIS_HOST = networks.cloud.ip.redis;
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
        networks."${networks.front.name}".ipv4_address = networks.front.ips.cloud;
        networks."${networks.cloud.name}".ipv4_address = networks.cloud.ips.cloud;
      };

      ### # Database # ###

      services."${names.database}".service = {
        # Image
        image = "mariadb:latest";
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
        networks."${networks.cloud.name}".ipv4_address = networks.cloud.ips.database;
      };

      ### # Redis # ###

      services."${names.redis}".service = {
        # Image
        image = "redis:latest";
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
        networks."${networks.cloud.name}".ipv4_address = networks.cloud.ips.redis;
      };

      ### # Proxy # ###

      services."${names.proxy}".service = let

        # Create the proxy configuration attr set for this container
        proxyConfiguration = my.containers.functions.createProxy {
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

    project.vault.settings = {

      # Networking
      networks."${networks.front.name}".external = true;

      ### # Vault # ###

      services.cloud.service = {
        # Image
        image = "vaultwarden/server:latest";
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
        networks."${networks.front.name}".ipv4_address = networks."${networks.front.name}".ips.vault;
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