{ pkgs, config, ... }:
let

  # Create all the services needed for the containers networks
  conatinerNetworksServices = pkgs.containerFunctions.addNetworks {
    dns = { range = "172.16.72.0/24"; };
    web = { range = "172.16.73.0/24"; };
  };

in {

  # Intialise all the container services
  systemd.services = conatinerNetworksService;

  # Set up docker containers
  virtualisation.oci-containers.containers = {

    ##############
    # DNS Server #
    ##############

    dns-up = rec {
      image = imageFile.imageName;
      imageFile = pkgs.containerImages.dns;
      extraOptions = [ "--network=dns" "--ip=172.16.72.200" ];
    };
    dns-block = {
      image = "pihole/pihole:latest";
      environment = {
        TZ = config.mine.system.timezone;
        DNSMASQ_LISTENING = "all";
        PIHOLE_DNS_ = "172.16.72.200";
      };
      environmentFiles = [ /data/local/containers/pihole/env/adblock.env ];
      volumes = [
        "/data/local/containers/pihole/config/etc:/etc/pihole"
        "/data/local/containers/pihole/config/dnsmasq:/etc/dnsmasq.d"
      ];
      ports = [
        "53:53/tcp"
        "53:53/udp"
        "81:80/tcp"
      ];
      extraOptions = [ "--dns=127.0.0.1" "--network=dns" "--ip=172.16.72.100" ];
    };

    ##############
    # NTP Server #
    ##############

    time = rec {
      image = "simonrupf/chronyd";
      environment = {
        TZ = config.mine.system.timezone;
        NTP_SERVERS = "time.cloudflare.com";
        ENABLE_NTS = "true";
      };
      ports = [
        "123:123/udp"
      ];
    };

    ###############
    # NUT Monitor #
    ###############

    nut = {
      image = "teknologist/webnut:latest";
      environment = {
        TZ = config.mine.system.timezone;
      };
      environmentFiles = [ /data/local/containers/nut/nut.env ];
      ports = [
        "82:6543/tcp"
      ];
      extraOptions = [ "--network=web" ];
    };

    #############
    # Dashboard #
    #############

    dash = rec {
      image = imageFile.imageName;
      imageFile = pkgs.containerImages.web { name = "dashboard"; url = "https://github.com/luis-caldas/personal"; };
      volumes = [
        "/data/local/containers/dash/config/other.json:/web/other.json:ro"
      ];
      extraOptions = [ "--network=web" "--ip=172.16.73.100" ];
    };

    ###########
    # FreeDNS #
    ###########

    freedns = rec {
      image = imageFile.imageName;
      imageFile = pkgs.containerImages.freedns;
      environmentFiles = [ /data/local/containers/noip/udns.env ];
      extraOptions = [ "--dns=172.16.72.100" "--network=dns" ];
    };

    ############
    # Asterisk #
    ############

    asterisk = rec {
      image = imageFile.imageName;
      imageFile = pkgs.containerImages.asterisk;
      volumes = [
        "/data/local/containers/asterisk/config/conf:/etc/asterisk/conf.mine"
        "/data/local/containers/asterisk/config/voicemail:/var/spool/asterisk/voicemail"
        "/data/local/containers/asterisk/config/record:/var/spool/asterisk/monitor"
        "/data/local/containers/asterisk/config/sounds:/var/lib/asterisk/sounds/mine"
        # Email files
        "/data/local/mail:/data/local/mail:ro"
        "/etc/msmtprc:/etc/msmtprc:ro"
      ];
      extraOptions = [ "--network=host" ];
    };
    # HTTP Server for files
    http-asterisk-user = rec {
      image = imageFile.imageName;
      imageFile = pkgs.containerImages.web {};
      volumes = [
        "/data/local/containers/asterisk/config/voicemail:/web/voicemail:ro"
        "/data/local/containers/asterisk/config/record:/web/monitor:ro"
      ];
      ports = [
        "8080:8080/tcp"
      ];
      extraOptions = [ "--network=web" ];
    };
    # Simple HTTP Server
    http-asterisk-kodi = rec {
      image = "halverneus/static-file-server:latest";
      volumes = [
        "/data/local/containers/asterisk/config/voicemail:/web/voicemail:ro"
        "/data/local/containers/asterisk/config/record:/web/monitor:ro"
      ];
      ports = [
        "8081:8080/tcp"
      ];
      extraOptions = [ "--network=web" ];
    };

    #################
    # Reverse Proxy #
    #################

    proxy = {
      image = "jc21/nginx-proxy-manager:latest";
      ports = [
        "80:80/tcp"
        "443:443/tcp"
        "7080:81/tcp"
      ];
      volumes = [
        "/data/local/containers/proxy:/data"
      ];
      extraOptions = [ "--network=web" ];
    };

  };

}