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

  # Auto snapshotting
  services.zfs.autoSnapshot.enable = config.mine.services.snapshot;

  # Avahi
  services.avahi = lib.mkIf config.mine.services.avahi {
    enable = true;
    nssmdns4 = true;
  };

  # Remote access
  services.sunshine = lib.mkIf config.mine.graphics.sunshine {
    enable = true;
    autoStart = false;
    capSysAdmin = true;
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

  # Virtualisation
  virtualisation.docker.enable = config.mine.services.docker.enable;
  # Set default backend for containers
  virtualisation.oci-containers.backend = "docker";
  # Disable live restore
  virtualisation.docker.liveRestore = false;
  # Networking
  virtualisation.docker.daemon.settings = {
    "default-address-pools" = [{
      base = "172.16.0.0/12";
      size = 24;
    }];
  };


  # libvirt configuration
  virtualisation.libvirtd = lib.mkIf config.mine.services.virtual.enable {
    enable = true;
    onBoot = "start";
    onShutdown = "shutdown";
    qemu.swtpm.enable = config.mine.services.virtual.swtpm;
  };

  # Enable VMware if wanted
  virtualisation.vmware.host.enable = config.mine.services.virtual.vmware;
  virtualisation.vmware.guest.enable = config.mine.services.virtual.vmware;
  virtualisation.vmware.guest.headless = !config.mine.graphics.enable;

  # Enable logiops service
  services.logiops.enable = config.mine.graphics.enable;

  # Printing
  services.printing = lib.mkIf config.mine.services.printing {
    enable = true;
    browsing = true;
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

  # Keep sshd installed but do not auto start
  systemd.services.sshd = lib.mkIf (!config.mine.services.ssh) {
    wantedBy = lib.mkForce [];
    restartTriggers = lib.mkForce [];
  };

  # fwupd
  services.fwupd.enable = config.mine.services.fwupd;

  # Add gotop if wanted
  systemd.services.gotopper = lib.mkIf config.mine.boot.top {
    after = [ "getty.target" ];
    description = "Show systems resources instead of terminal";
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
