{ pkgs, lib, config, ... }:
let

  allUps = rec {

    # Wait time for shutdown on client machines
    shutdownWait = 3 * 60;  # In seconds

    # Path to be used
    path = "/var/lib/nut";

    # UPS Scheduler Script
    clientScript = pkgs.writeShellScript "client-script" ''
      case $1 in
        on-batt)
          ${pkgs.util-linux}/bin/logger -t upssched-cmd "UPS On Battery state exceeded timer value."
          ${pkgs.systemd}/bin/shutdown now
          ;;
        *)
          ${pkgs.util-linux}/bin/logger -t upssched-cmd "UPS Unrecognized event: $1"
          ;;
      esac
    '';

    # UPS Scheduler Configuration
    clientSched = pkgs.writeText "client-schedule" ''
      CMDSCRIPT ${clientScript}

      PIPEFN ${path}/upssched.pipe
      LOCKFN ${path}/upssched.lock

      AT ONBATT * START-TIMER on-batt ${builtins.toString shutdownWait}
      AT ONLINE * CANCEL-TIMER on-batt
    '';

    # Server Script
    serverScript = pkgs.writeShellScript "server-script" ''
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
      # DEBUG_MIN = 9;
    };

    # Default Notify
    defaultNotify = "SYSLOG+EXEC";

    # Map Notify Flags
    mapNotifyFlags = listTypes: notification:
      map (each: [ each notification ]) listTypes;

  };

in {

  # Overlay for all the functions
  nixpkgs.overlays = [

    # The overlay
    (final: prev: let

      # Name of the attribute we are getting into
      attrName = "functions";

      # Our current functions
      current.ups = allUps;

    in {

      # The functions
      "${attrName}" = if builtins.hasAttr attrName prev then (prev."${attrName}" // current) else current;

    })

  ];

}
