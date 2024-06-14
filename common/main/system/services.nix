{ pkgs, lib, config, ... }:
{

  # Open SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = lib.mkForce "no";
      KbdInteractiveAuthentication = false;
      PasswordAuthentication = false;
    };
  };

  # Avahi
  services.avahi = lib.mkIf config.mine.services.avahi {
    enable = true;
    nssmdns4 = true;
  };

  # Prometheus
  services.prometheus = let
    localConnection = "127.0.0.1";
    # Create the web file
    # Adding authentication and SSL
    webFile = pkgs.writeText "web-config.yml" (builtins.toJSON {
      basic_auth_users = {
        user = lib.strings.fileContents config.mine.services.prometheus.password;
      };
      tls_server_config = {
        cert_file = config.mine.services.prometheus.ssl.cert;
        key_file = config.mine.services.prometheus.ssl.key;
      };
    });
  in {
    enable = config.mine.services.prometheus.enable;
    exporters.node = {
      enable = config.mine.services.prometheus.enable;
      enabledCollectors = [ "systemd" ] ++
        config.mine.services.prometheus.collectors;
      listenAddress = localConnection;
    };
    scrapeConfigs = [{
      job_name = "node";
      static_configs = [{
        targets = [ "${localConnection}:${toString config.services.prometheus.exporters.node.port}" ];
      }];
    }];
    webConfigFile = "${webFile}";
  };

  # Setup ProxyChains
  programs.proxychains = {
    enable = true;
    localnet = "127.0.0.0/255.0.0.0";
    quietMode = false;
    proxyDNS = true;
    proxies = {
      tor = {
        type = "socks5";
        host = "127.0.0.1";
        port = 9050;
      };
      local = {
        type = "socks5";
        host = "127.0.0.1";
        port = 30085;
      };
    };
  };

  # Vitualisation
  virtualisation.docker.enable = config.mine.services.docker;
  # Set default backend for containers
  virtualisation.oci-containers.backend = "docker";

  # libvirt config
  virtualisation.libvirtd = lib.mkIf config.mine.services.virtual.enable {
    enable = true;
    onBoot = "start";
    onShutdown = "shutdown";
    qemu.ovmf = {
      enable = true;
      packages = [ pkgs.OVMFFull.fd ];
    };
    qemu.swtpm.enable = config.mine.services.virtual.swtpm;
  };

  # Enable vmware if wanted
  virtualisation.vmware.host.enable = config.mine.services.virtual.vmware;
  virtualisation.vmware.guest.enable = config.mine.services.virtual.vmware;
  virtualisation.vmware.guest.headless = !config.mine.graphics.enable;

  # Enable logiops service
  services.logiops.enable = config.mine.graphics.enable;

  # Printing
  services.printing = lib.mkIf config.mine.services.printing {
    enable = true;
    browsing = true;
    logLevel = "debug";
    # Extra configuration
    browsedConf = "
      BrowseDNSSDSubTypes _cups,_print
      BrowseLocalProtocols All
      BrowseRemoteProtocols All
      BrowseProtocols All
      CreateIPPPrinterQueues All
      CreateIPPPrinterQueues driverless
    ";
    # All the available drivers
    drivers = with pkgs; [
        cups-zj-58
        brlaser
        gutenprint
      ] ++
      # GutenPrint for supported architecture
      (if pkgs.stdenv.hostPlatform.isx86_64 then [
        gutenprintBin
      ] else []) ++
      # Brother drivers for supported architectures
      (if (!pkgs.stdenv.hostPlatform.isAarch) then [
        brgenml1lpr
        brgenml1cupswrapper
      ] else []);
  };

  # Scanning
  hardware.sane = lib.mkIf config.mine.services.printing {
    enable = true;
    extraBackends = with pkgs; [
      sane-airscan
    ];
  };

  # Printer applets
  programs.system-config-printer.enable =
    config.mine.graphics.enable && config.mine.services.printing;

  # Override service
  systemd.services.sshd = lib.mkIf (!config.mine.services.ssh) {
    after = lib.mkForce [];
    wantedBy = lib.mkForce [];
    restartTriggers = lib.mkForce [];
  };

  # Add gotop if wanted
  systemd.services.gotopper = lib.mkIf config.mine.boot.top {
    after = [ "getty.target" ];
    serviceConfig = {
      ExecStart = [ "${pkgs.gotop}/bin/gotop" ];
      Type = "idle";
      Restart = "always";
      RestartSec = "0";
      StandardInput = "tty";
      StandardOutput = "tty";
      TTYPath = "/dev/tty7";
      TTYReset = "yes";
      TTYVHangup = "yes";
      TTYVTDisallocate = "yes";
      IgnoreSIGPIPE = "no";
      SendSIGHUP = "yes";
      ExecStartPost = "${pkgs.kbd}/bin/chvt 7";
    };
    wantedBy = [ "multi-user.target" ];
  };

}
