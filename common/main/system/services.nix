{ my, mfunc, lib, pkgs, mpkgs, ... }:
{

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = lib.mkForce "no";
      KbdInteractiveAuthentication = false;
      PasswordAuthentication = false;
    };
  };

  # Enable avahi
  services.avahi = mfunc.useDefault my.config.services.avahi {
    enable = true;
    nssmdns = true;
  } {};

  # Setup proxychains
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
  virtualisation.docker.enable = my.config.services.docker;

  # Set default backend
  virtualisation.oci-containers.backend = "docker";

  # libvirt config
  virtualisation.libvirtd = mfunc.useDefault my.config.services.virt.enable {
    enable = true;
    onBoot = "start";
    onShutdown = "shutdown";
    qemu.ovmf = {
      enable = true;
      packages = [ pkgs.OVMFFull.fd ];
    };
    qemu.swtpm.enable = my.config.services.virt.swtpm;
  } {};

  # PCSC
  services.pcscd = {
    enable = true;
    plugins = [ pkgs.acsccid ];
  };

  # Enable logiops service (logitech MX mice)
  services.logiops.enable = my.config.graphical.enable;

  # Printing
  services.printing = mfunc.useDefault my.config.services.printing {
    enable = true;
    drivers = with pkgs; [
        cups-zj-58
        brlaser
        gutenprint
      ] ++
      (mfunc.useDefault (my.arch == my.reference.x64) [
        gutenprintBin
      ] []) ++
      (mfunc.useDefault ((my.arch == my.reference.x64) || (my.arch == my.reference.x86)) [
        brgenml1lpr
        brgenml1cupswrapper
      ] []);
    browsing = true;
    browsedConf = "
      BrowseDNSSDSubTypes _cups,_print
      BrowseLocalProtocols All
      BrowseRemoteProtocols All
      BrowseProtocols All
      CreateIPPPrinterQueues All
      CreateIPPPrinterQueues driverless
    ";
    logLevel = "debug";
  } {};

  # Scanning
  hardware.sane = mfunc.useDefault my.config.services.printing {
    enable = true;
    extraBackends = with pkgs; [
      sane-airscan
    ];
  } {};

  # Printer applets
  programs.system-config-printer.enable =
    my.config.graphical.enable && my.config.services.printing;

  # My own systemd services
  systemd.services = {} //
  # Enable SSH only if wanted
  (mfunc.useDefault (!my.config.services.ssh) {
    sshd = {
      wantedBy = lib.mkForce [];
      restartTriggers = lib.mkForce [];
    };
  } {}) //
  # Whole screen tty mode for a nice top window
  (mfunc.useDefault my.config.boot.top
  # Add gotop on TTY8 if wanted
  ({
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
  }) {});

}
