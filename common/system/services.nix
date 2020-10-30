{ my, mfunc, lib, pkgs, ... }:
{

  # SSH mate
  services.openssh.enable = my.config.services.ssh;

  # Docker for my servers
  virtualisation.docker.enable = my.config.services.docker;

  # DBus session sockets
  services.dbus.socketActivated = true;

  # Auto start stuff
  systemd.services.starter = {
    script = lib.concatStrings (map (s: s + "\n") my.config.services.startup.start);
    wantedBy = [ "multi-user.target" ];
  };

  # PCSC
  services.pcscd = {
    enable = true;
    plugins = [ pkgs.acsccid ];
  };

  # Non free printer drivers
  nixpkgs.config.allowUnfree = true;

  # Udev configuration
  services.udev.packages = [ pkgs.rtl-sdr ];

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

  # Create and permit files
  systemd.services.createer = {
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
  systemd.services.filer = {
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

}
