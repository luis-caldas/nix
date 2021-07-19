{ my, mfunc, lib, pkgs, ... }:
{

  # SSH
  services.openssh = {
    enable = my.config.services.ssh;
    # Enable X11 forwarding if graphical is enabled
    forwardX11 = my.config.services.ssh && my.config.graphical.enable;
  };

  # Docker for my servers
  virtualisation.docker.enable = my.config.services.docker;

  # PCSC
  services.pcscd = {
    enable = true;
    plugins = [ pkgs.acsccid ];
  };

  # Fingerprint
  services.fprintd = mfunc.useDefault my.config.services.fingerprint {
    enable = true;
  } {};

  # Udev configuration
  services.udev.packages = [ pkgs.rtl-sdr ];

  # Enable logiops service (logitech MX mice)
  services.logiops.enable = true;

  # Printing
  services.printing = mfunc.useDefault my.config.services.printing {
    enable = true;
    drivers = with pkgs; [
        cups-zj-58
        brlaser
        gutenprint
      ] ++
      (mfunc.useDefault my.config.x86_64 [
        gutenprintBin
        brgenml1lpr
        brgenml1cupswrapper
      ] []);
    browsedConf = "
      CreateIPPPrinterQueues All
    ";
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

  # Avahi for printer discovery
  services.avahi = mfunc.useDefault my.config.services.printing {
    enable = true;
    nssmdns = true;
  } {};

  # My own systemd services
  systemd.services = {

    # Auto start stuff
    starter = {
      script = lib.concatStrings (map (s: s + "\n") my.config.services.startup.start);
      wantedBy = [ "multi-user.target" ];
    };

    # Create and permit files
    createer = {
      script = lib.concatStrings (
        map (
          s:
          "touch ${s}" + "\n" +
          "chown :${my.config.system.filer} ${s}" + "\n" +
          "chmod g+rw ${s}" + "\n"
        )
        my.config.services.startup.create
      );
      wantedBy = [ "multi-user.target" ];
    };

    # Files permissions
    filer = {
      script = lib.concatStrings (
        map (
          s:
          "chown :${my.config.system.filer} ${s}" + "\n" +
          "chmod g+rw ${s}" + "\n"
        )
        my.config.services.startup.permit
      );
      wantedBy = [ "multi-user.target" ];
    };

  } // (mfunc.useDefault my.config.boot.top
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
