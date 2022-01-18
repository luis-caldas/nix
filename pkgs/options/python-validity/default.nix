{ config, lib, pkgs, mpkgs, ... }:
with lib;
let

  cfg = config.services.python-validity;

  # Firmware variables
  firmwarePath = ./6_07f_lenovo_mis_qm.xpfwext;
  firmwareName = baseNameOf firmwarePath;

  # Var reasign
  packageInstall = mpkgs.python3Packages.python-validity;

in {

  options.services.python-validity = {

    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable `python-validity`
      '';
    };

    firmwareFile = mkOption {
      type = types.path;
      default = firmwarePath;
      description = ''
        File that contains the firmware for your fingerprint reader
      '';
    };

  };

  config = mkIf cfg.enable {

    # Create the service
    systemd.services.python-validity = {
      description = "Thinkpad Fingerprint Service";
      startLimitIntervalSec = 0;
      serviceConfig = {
        Type = "simple";
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /var/lib/python-validity";
        ExecStart = "${packageInstall}/lib/python-validity/dbus-service";
        User = "root";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        Restart = "on-failure";
      };
      wantedBy = [ "multi-user.target" ];
    };

    # Add the bin packages to the system as well
    environment.systemPackages = [ packageInstall ];

    # Add given firmware file
    environment.etc."python-validity/${firmwareName}".source = cfg.firmwareFile;

    # Add dbus policies
    services.dbus.packages = [ mpkgs.python3Packages.python-validity ];

  };

}
