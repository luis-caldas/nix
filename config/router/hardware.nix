{ my, lib, config, mfunc, pkgs, ... }:
let

  # Create all the services needed for the containers networks
  conatinerNetworksService = let
    # Names of networks and their subnets
    networks = {
      dns = "172.16.72.0/24";
      web = "172.16.73.0/24";
    };
  in
    my.containers.functions.addNetworks networks;

in {

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "vfio-pci" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelParams = [ "pcie_aspm=off" "amd_iommu=on" "iommu=pt" "pci=noaer" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # VFIO overrides for vms
  boot.initrd.preDeviceCommands = ''
    devices="0000:05:00.0 0000:05:00.1"
    for each_device in $devices; do
      echo "vfio-pci" > /sys/bus/pci/devices/$each_device/driver_override
    done
    modprobe -i vfio-pci
  '';

  # Enable ip forwarding
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  # Networling
  networking = {
    useDHCP = false;
    dhcpcd.extraConfig = ''
      noipv4ll
    '';
    networkmanager.enable = lib.mkForce false;
    interfaces = {
      enp4s0.useDHCP = true;
      firewall-bridge = {
        useDHCP = true;
        macAddress = "ff:54:ff:00:00:01";
      };
    };
    bridges.firewall-bridge.interfaces = [];
  };

  # Virtualisation options
  virtualisation.libvirtd.onShutdown = "shutdown";

  # Services needed
  systemd.services = {
    # Autostart serial getty connection
    "serial-getty@ttyRECOVER" = {
      enable = true;
      wantedBy = [ "getty.target" ];
      serviceConfig.Restart = "always";
    };
  } //
  # Add the container network services too
  conatinerNetworksService;

  # UPS configuration
  power.ups = {
    enable = true;
    mode = "netserver";
    ups.apc = {
      port = "auto";
      driver = "usbhid-ups";
      description = "APC Smart 2200VA UPS";
      directives = lib.mapAttrsToList (name: value: "${name} = \"${value}\"") {
        vendorid = "051D";
        productid = "0002";
      };
    };
  };
  users = {
    users.nut = {
      isSystemUser = true;
      group = "nut";
      home = "/var/lib/nut";
      createHome = true;
    };
    groups.nut = { };
  };
  environment.etc = {
    "nut/upsd.conf".source = "/data/local/nut/upsd.conf";
    "nut/upsd.users".source = "/data/local/nut/upsd.users";
    "nut/upsmon.conf".source = "/data/local/nut/upsmon.conf";
  };

  # Configure email sender
  programs.msmtp = {
    enable = true;
    setSendmail = true;
    defaults = {
      aliases = "/data/local/mail/alias";
      port = 465;
      tls_trust_file = "/etc/ssl/certs/ca-certificates.crt";
      tls = "on";
      auth = "login";
      tls_starttls = "off";
    };
    accounts = let
      mailDomain = mfunc.safeReadFile /data/local/mail/domain;
      accountMail = mfunc.safeReadFile /data/local/mail/account;
    in
    {
      default = {
        host = mailDomain;
        passwordeval = "${pkgs.coreutils}/bin/cat /data/local/mail/password";
        user = accountMail;
        from = accountMail;
      };
    };
  };

  # Set up docker containers
  virtualisation.oci-containers.containers = {

    # DNS Server
    dns-up = rec {
      image = imageFile.imageName;
      imageFile = my.containers.images.dns;
      extraOptions = [ "--network=dns" "--ip=172.16.72.200" ];
    };
    dns-block = {
      image = "pihole/pihole:latest";
      environment = {
        TZ = my.config.system.timezone;
        DNSMASQ_LISTENING = "all";
        DNS1 = "172.16.72.200";
        DNS2 = "172.16.72.200";
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

    # NUT server monitor
    nut = {
      image = "teknologist/webnut:latest";
      environment = {
        TZ = my.config.system.timezone;
      };
      environmentFiles = [ /data/local/containers/nut/nut.env ];
      ports = [
        "82:6543/tcp"
      ];
      extraOptions = [ "--network=web" ];
    };

    # Dashboard website
    dash = rec {
      image = imageFile.imageName;
      imageFile = my.containers.images.web { name = "dashboard"; url = "https://github.com/luis-caldas/personal"; };
      volumes = [
        "/data/local/containers/dash/config/other.json:/web/other.json:ro"
      ];
      extraOptions = [ "--network=web" "--ip=172.16.73.100" ];
    };
    # Proxy HTTPS
    dash-proxy = my.containers.functions.createProxy {
      name = "dash";
      net = {
        name = "web";
        ip = "172.16.73.100";
        port = "8080";
      };
      port = "443";
      ssl = {
        key = "/data/local/containers/dash/ssl/main.key";
        cert = "/data/local/containers/dash/ssl/main.pem";
      };
    };
    # Redirector
    dash-redirector = my.containers.functions.createRedirector;

    # DNS updater
    noip = rec {
      image = imageFile.imageName;
      imageFile = my.containers.images.udns;
      environmentFiles = [ /data/local/containers/noip/udns.env ];
      extraOptions = [ "--dns=172.16.72.100" "--network=dns" ];
    };

    # Asterisk container
    asterisk = rec {
      image = imageFile.imageName;
      imageFile = my.containers.images.asterisk;
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
    # Asterisk HTTP Server for users
    http-asterisk-user = rec {
      image = imageFile.imageName;
      imageFile = my.containers.images.web {};
      volumes = [
        "/data/local/containers/asterisk/config/voicemail:/web/voicemail:ro"
        "/data/local/containers/asterisk/config/record:/web/monitor:ro"
      ];
      ports = [
        "8080:8080/tcp"
      ];
      extraOptions = [ "--network=web" ];
    };
    # Asterisk HTTP Server for kodi
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

    # HTTP Server manuals
    man-nix = rec {
      image = imageFile.imageName;
      imageFile = my.containers.images.web {};
      volumes = [
        "${pkgs.nix.doc}/share/doc/nix/manual:/web:ro"
      ];
      ports = [
        "8090:8080/tcp"
      ];
      extraOptions = [ "--network=web" ];
    };
    man-nixos = rec {
      image = imageFile.imageName;
      imageFile = my.containers.images.web {};
      volumes = [
        "${config.system.build.manual.manualHTML}/share/doc/nixos:/web:ro"
      ];
      ports = [
        "8091:8080/tcp"
      ];
      extraOptions = [ "--network=web" ];
    };
    man-down = rec {
      image = imageFile.imageName;
      imageFile = my.containers.images.web {};
      volumes = let
        myDocs = pkgs.stdenv.mkDerivation rec {
          name = "documentation";
          phases = [ "unpackPhase" "patchPhase" "buildPhase" "installPhase" ];
          nativeBuildInputs = [ pkgs.python3Packages.mkdocs-material ];
          mkDocsConfig = pkgs.writeTextFile rec {
            name = "config";
            destination = "/mkdocs.yml";
            text = ''
              site_name: NixOs Documentation
              site_url: https://example.com
              docs_dir: ../doc
              markdown_extensions:
                  - extra
                  - toc:
                      permalink: True
              theme:
                  name: material
                  palette:
                      scheme: slate
                      primary: black
                      accent: indigo
            '';
           };
           srcs = [ "${<nixpkgs/doc>}" mkDocsConfig ];
           sourceRoot = ".";
           patchPhase = ''
             find doc -iname "*.md" -print0 | xargs -0 sed -i -E 's/^(#{1,6}\s*.*)\s*\{.*\}\s*$/\1/'
           '';
           buildPhase = ''
             mkdir -p "out"
             "${pkgs.mkdocs}/bin/mkdocs" build --config-file "config/mkdocs.yml" --site-dir ../out
           '';
           installPhase = ''
             mkdir -p "$out"
             mv out/ "$out/web"
           '';
         };
      in [
        "${myDocs}/web:/web:ro"
      ];
      ports = [
        "8092:8080/tcp"
      ];
      extraOptions = [ "--network=web" ];
    };

  };

  fileSystems."/" =
    { device = "vimmer/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/B7F0-3A34";
      fsType = "vfat";
    };

  fileSystems."/home" =
    { device = "vimmer/home";
      fsType = "zfs";
    };

  fileSystems."/data/vms" =
    { device = "vimmer/vms";
      fsType = "zfs";
    };

  fileSystems."/data/local" =
    { device = "vimmer/data";
      fsType = "zfs";
    };

  fileSystems."/nix" =
    { device = "vimmer/nix";
      fsType = "zfs";
    };

  fileSystems."/tmp" =
    { device = "vimmer/tmp";
      fsType = "zfs";
    };

  swapDevices =
    [ { device = "/dev/zvol/vimmer/swap"; }
    ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  system.stateVersion = "23.05";

}
