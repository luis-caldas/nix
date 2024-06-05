{ config, ... }:
let

  allUps = rec {

    # Path to be used
    path = "/var/lib/nut";

    # UPS Scheduler Script
    clientScript = pkgs.writeShellScript ''
      case $1 in
        on-batt)
          ${util-linux}/bin/logger -t upssched-cmd "UPS On Battery state exceeded timer value."
          ;;
        *)
          ${util-linux}/bin/logger -t upssched-cmd "UPS Unrecognized event: $1"
          ;;
      esac
    '';

    # UPS Scheduler Configuration
    clientSched = pkgs.writeText ''
      CMDSCRIPT ${clientScript}

      PIPEFN ${path}/upssched.pipe
      LOCKFN ${path}/upssched.lock

      AT ONBATT * START-TIMER on-batt 180
      AT ONLINE * CANCEL-TIMER on-batt
    '';

  };

in {

  # Overlay
  nixpkgs.overlays = lib.mkIf config.mine.ups [

    # The overlay
    (final: prev: {

      # Add the networks
      ups = allUps;

    })

  ];

}