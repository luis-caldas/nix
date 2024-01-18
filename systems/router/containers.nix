{ pkgs, lib, config, ... }:
let

       ########
  ### # Config # ###
       ########

  # Configure all the needed networks
  networks = {
    ### # Front # ###
    front.name = "front";
    ### # Time # ###
    time.name = "time";
    ### # FreeDNS # ###
    update.name = "update";
    ### # DNS # ###
    dns = {
      name = "dns";
      subnet = "172.16.20.0/24"; gateway = "172.16.20.1";
      # IPs
      ips = {
        dns = "172.16.20.11";
        dnsUp = "172.16.20.10";
      };
    };
  };

  # Configure the needed names
  names = {
    # Front
    front = "front";
    # Base
    dns = "dns";
    dnsUp = "dns-up";
    time = "time";
    # Update
    update = "freedns";
    # Asterisk
    asterisk = {
      app = "asterisk";
      web = { simple = "asterisk-web-simple"; normal = "asterisk-web-normal"; };
    };
    # Monitor
    nut = "nut";
    # Web
    dash = "dash";
  };

  # Naming for the projects
  projects = {
    front = "front";
    base = "base";
    asterisk = "asterisk";
    nut = "nut";
    web = "web";
  };

  # Service extension
  serviceExtension = "service";

in {

  # All the services dependencies
  systemd.services."${projects.base}".requires = [ "${projects.front}.${serviceExtension}" ];
  systemd.services."${projects.asterisk}".requires = [ "${projects.front}.${serviceExtension}" ];
  systemd.services."${projects.nut}".requires = [ "${projects.front}.${serviceExtension}" ];
  systemd.services."${projects.web}".requires = [ "${projects.front}.${serviceExtension}" ];

  # Virtualisation itself
  virtualisation.arion = {

    #########
    # Front #
    #########

    # All services that will serve the front

    projects.front = {
      serviceName = projects.front;
      settings = {

        # Networking
        networks."${networks.front.name}" = {
          name = networks.front.name;
          ipam.config = [{ inherit (networks.front) subnet gateway; }];
        };

             #######
        ### # Proxy # ###
             #######

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
    };

    ########
    # Base #
    ########

    # Projects needed for a basic router functionality

    projects.base = {
      serviceName = projects.base;
      settings = {

        # Networking
        networks."${networks.dns.name}" = {
          name = networks.dns.name;
          ipam.config = [{ inherit (networks.dns) subnet gateway; }];
        };
        networks."${networks.time.name}" = {
          name = networks.time.name;
          ipam.config = [{ inherit (networks.time) subnet gateway; }];
        };
        networks."${networks.front.name}".external = true;

             #####
        ### # DNS # ###
             #####

        # Upstream DNS server
        services."${names.dnsUp}" = {
          build.image = lib.mkForce pkgs.containers.dns;
          service = {
            # Name
            container_name = names.dnsUp;
            # Networking
            networks."${networks.dns.name}".ipv4_address = networks.dns.ips.dnsUp;
          };
        };

             ########
        ### # PiHole # ###
             ########

        # PiHole
        services."${names.dns}".service = {

          # Image
          image = "pihole/pihole:latest";

          # Name
          container_name = names.dns;

          # Environment
          environment = {
            TZ = config.mine.system.timezone;
            DNSMASQ_LISTENING = "all";
            PIHOLE_DNS_ = networks.dns.ips.dnsUp;
          };
          env_file = [ "/data/local/containers/pihole/env/adblock.env" ];

          # Volumes
          volumes = [
            "/data/local/containers/pihole/config/etc:/etc/pihole"
            "/data/local/containers/pihole/config/dnsmasq:/etc/dnsmasq.d"
          ];

          # Networking
          ports = [
            "53:53/tcp"
            "53:53/udp"
          ];
          dns = [ "127.0.0.1" ];
          networks = [ networks.dns.name networks.front.name ];

        };

             ######
        ### # Time # ###
             ######

        services."${names.time}".service = {
          # Image file
          image = "simonrupf/chronyd:latest";
          # Name
          container_name = names.time;
          # Environment
          environment = {
            TZ = config.mine.system.timezone;
            NTP_SERVERS = "time.cloudflare.com";
            ENABLE_NTS = "true";
          };
          # Networking
          ports = [
            "123:123/udp"
          ];
          networks = [ networks.time.name ];
        };


      };
    };

    ##########
    # Update #
    ##########

    # Dynamic DNS

    projects.update.settings = {

      # Networking
      networks."${networks.update.name}" = {
        name = networks.update.name;
        ipam.config = [{ inherit (networks.update) subnet gateway; }];
      };

           #########
      ### # FreeDNS # ###
           #########

      services."${names.update}" = {
        # Image
        build.image = lib.mkForce pkgs.containers.freedns;
        # Configuration
        service = {
          # Name
          container_name = names.update;
          # Environment
          env_file = [ "/data/local/containers/noip/udns.env" ];
          # Networking
          networks = [ networks.update.name ];
        };
      };

    };

    ############
    # Asterisk #
    ############

    projects.asterisk = {
      serviceName = projects.asterisk;
      settings = {

        # Networking
        networks."${networks.front.name}".external = true;

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
            networks = [ networks.front.name ];
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
          networks = [ networks.front.name ];
        };

      };
    };

    #######
    # NUT #
    #######

    # NUT Monitor process

    projects.nut = {
      serviceName = projects.nut;
      settings = {

        # Networking
        networks."${networks.front.name}".external = true;

             #####
        ### # NUT # ###
             #####

        services."${names.nut}".service = {
          # Image
          image = "teknologist/webnut:latest";
          # Name
          container_name = names.nut;
          # Environment
          environment = {
            TZ = config.mine.system.timezone;
          };
          env_file = [ "/data/local/containers/nut/nut.env" ];
          # Networking
          networks = [ networks.front.name ];
        };

      };
    };

    #######
    # Web #
    #######

    projects.web = {
      serviceName = projects.web;
      settings = {

        # Networking
        networks."${networks.front.name}".external = true;

             ######
        ### # Dash # ###
             ######

        services."${names.dash}" = {
          # Image
          build.image = lib.mkForce (pkgs.containers.web { name = "dashboard"; url = "https://github.com/luis-caldas/personal"; });
          # Options
          service = {
            # Name
            container_name = names.dash;
            # Volumes
            volumes = [
              "/data/local/containers/dash/config/other.json:/web/other.json:ro"
            ];
            # Networking
            networks = [ networks.front.name ];
          };
        };

      };
    };

  };

}