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

    # Server Script
    serverScript = pkgs.writeShellScript ''
      time_now="$(date +"%Y/%m/%d @ %H:%M:%S")"
      {
        echo -e "Subject: [UPS]: ''${NOTIFYTYPE} at ''${time_now}\r\n\r\nUPS: ''${UPSNAME}\r\nAlert type: ''${NOTIFYTYPE}\r\n\r\n";
        ${pkgs.nut}/bin/upsc "''${UPSNAME}";
        echo -e "\r\n\r\n"
      } | ${pkgs.msmtp}/bin/msmtp root
    '';

    # Shared Configurations
    sharedConf = {
      # User to run
      RUN_AS_USER = "root";
      # Binaries
      SHUTDOWNCMD = "${pkgs.systemd}/bin/shutdown now";
      # Number of power supplies before shutting down
      MINSUPPLIES = 1;
      # Query intervals
      POLLFREQ = 1;
      POLLFREQALERT = 1;
      # Debug
      DEBUG_MIN = 9;
    };

    # Default Notify
    defaultNotify = "SYSLOG+EXEC";

    # Map Notify Flags
    mapNotifyFlags = listTypes: notification:
      map (each: [ each notification ]) listTypes;

  };

in {

  # Overlay
  nixpkgs.overlays = lib.mkIf config.mine.ups [

    # The overlay
    (final: prev: {

      # Add the networks
      uninterruptible = allUps;

    })

  ];

}