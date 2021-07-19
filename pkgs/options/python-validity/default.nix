{ config, lib, pkgs, mpkgs, ... }:
with lib;
let

  cfg = config.services.python-validity;

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
      default = ./6_07f_lenovo_mis_qm.xpfwext;
      description = ''
        File that contains the firmware for your fingerprint reader
      '';
    };

  };

  config = mkIf cfg.enable {

    # Create the service
    systemd.services.python-validity = {
      description = "Fingerprint package for Thinkpads";
      startLimitIntervalSec = 0;
      serviceConfig = {
        Type = "simple";
        ExecStart = "${mpkgs.python3Packages.python-validity}/lib/python-validity/dbus-service --debug";
        User = "root";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        Restart = "on-failure";
      };
      wantedBy = [ "multi-user.target" ];
    };

    # Add given firmware file
    #environment.etc."python-validity/$(baseNameOf cfg.firmwareFile)".source = cfg.firmwareFile;

    # Add dbus policies
    services.dbus.packages = [ mpkgs.python3Packages.python-validity ];

  };

}
