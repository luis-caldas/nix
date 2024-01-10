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
    nssmdns = true;
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
  # virtualisation.vmware.host.enable = config.mine.production.software && config.mine.services.virtual.enable;
  # virtualisation.vmware.guest.enable = config.mine.production.software && config.mine.services.virtual.enable;
  virtualisation.vmware.guest.headless = !config.mine.graphical.enable;

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

  # My own systemd services
  systemd.services = {} //

  # Enable SSH only if wanted
  (lib.mkIf (!config.mine.services.ssh) {
    sshd = {
      wantedBy = lib.mkForce [];
      restartTriggers = lib.mkForce [];
    };
  }) //

  # Whole screen tty mode for a nice top window
  (lib.mkIf config.mine.boot.top
  # Add gotop on TTY8 if wanted
  {
    gotopper = {
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
  });

}
