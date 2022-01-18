{ config, lib, pkgs, mpkgs, ... }:
with lib;
let

  cfg = config.services.open-fprintd;

in {

  options.services.open-fprintd = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable `open-fprintd`
      '';
    };

  };

  config = mkIf cfg.enable {

    systemd.services.open-fprintd = {
      description = "Open FPrint Daemon";
      startLimitIntervalSec = 0;
      serviceConfig = {
        Type = "simple";
        ExecStart = "${mpkgs.python3Packages.open-fprintd}/lib/open-fprintd/open-fprintd";
        User = "root";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        Restart = "on-failure";
      };
      wantedBy = [ "multi-user.target" ];
    };

    # Add dbus policies
    services.dbus.packages = [ mpkgs.python3Packages.open-fprintd ];

  };

}
