{ pkgs, lib, config, ... }:
{

  virtualisation.arion = {

    projects.all.settings = let

      # Configure the networking
      netw = {

        # DNS Network
        dns = {
          subnet = "172.16.72.0/24";
          gateway = "172.16.72.1";
          # Configure IPs
          ips = {
            dns = "172.16.72.11";
            dnsUp = "172.16.72.10";
          };
        };

        # Web Network
        web = {

          subnet = "172.16.73.0/24";
          gateway = "172.16.73.1";

          # Configure IPs
          ips = {
            dash = "172.16.73.10";
            nut = "172.16.73.20";

            asteriskWeb = "172.16.73.30";
            asteriskSimple = "172.16.73.31";
          };

        };

      };

    in {

      # Configure networking
      networks = lib.attrsets.mapAttrs (
        eachName: eachValue:
            { ipam.config = [{ inherit (eachNetwork) subnet gateway; }]; }
      ) netw;

      ##############
      # DNS Server #
      ##############

      # Upstream DNS server
      services.dns-up = {
        build.image = lib.mkForce pkgs.containerImages.dns;
        service = {
          networks.dns.ipv4_address = netw.dns.ips.dnsUp;
        };
      };

      # PiHole
      services.dns.service = {
        image = "pihole/pihole:latest";

        # Environment
        environment = {
          TZ = config.mine.system.timezone;
          DNSMASQ_LISTENING = "all";
          PIHOLE_DNS_ = netw.dns.ips.dnsUp;
        };
        env_file = [ "data/local/containers/pihole/env/adblock.env" ];

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
        networks.dns.ipv4_address = netw.dns.ips.dns;

      };

      ###########
      # FreeDNS #
      ###########

      services.freedns = {
        # Image
        build.image = lib.mkForce pkgs.containerImages.freedns;
        # Environment
        service.env_file = [ "/data/local/containers/noip/udns.env" ];
      };

      ##############
      # NTP Server #
      ##############

      services.time.service = {
        # Image file
        image = "simonrupf/chronyd:latest";
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
      };

      ###############
      # NUT Monitor #
      ###############

      services.nut.service = {
        # Image
        image = "teknologist/webnut:latest";
        # Environment
        environment = {
          TZ = config.mine.system.timezone;
        };
        env_file = [ "/data/local/containers/nut/nut.env" ];
        # Networking
        networks.web.ipv4_address = netw.web.ips.nut;
      };

      ############
      # Asterisk #
      ############

      services.asterisk = {
        # Image
        build.image = lib.mkForce pkgs.containerImages.asterisk;
        # Options
        service = {
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

      #############
      # Dashboard #
      #############

      services.dash = {
        # Image
        build.image = lib.mkForce (pkgs.containerImages.web { name = "dashboard"; url = "https://github.com/luis-caldas/personal"; });
        # Options
        service = {
          # Volumes
          volumes = [
            "/data/local/containers/dash/config/other.json:/web/other.json:ro"
          ];
          # Networking
          networks.web.ipv4_address = netw.web.ips.dash;
        };
      };

      ################
      # Asterisk Web #
      ################

      # Normal
      services.http-asterisk-user = {
        # Image
        build.image = lib.mkForce (pkgs.containerImages.web {});
        # Options
        service = {
          # Volumes
          volumes = [
            "/data/local/containers/asterisk/config/voicemail:/web/voicemail:ro"
            "/data/local/containers/asterisk/config/record:/web/monitor:ro"
          ];
          # Networking
          networks.web.ipv4_address = netw.web.ips.asteriskWeb;
        };
      };

      # Simple
      services.http-asterisk-simple.service = {
        # Image
        image = "halverneus/static-file-server:latest";
        # Volumes
        volumes = [
          "/data/local/containers/asterisk/config/voicemail:/web/voicemail:ro"
          "/data/local/containers/asterisk/config/record:/web/monitor:ro"
        ];
        # Networking
        networks.web.ipv4_address = netw.web.ips.asteriskSimple;
      };

      #################
      # Reverse Proxy #
      #################

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
          "7080:81/tcp"
        ];
        networks = [ "web" ];
      };

    };

  };

}