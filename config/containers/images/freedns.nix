{ baseImage, information, pkgs, ... }:

###########
# FreeDNS #
###########

# FreeDNS updater

let

  # Log Files
  log = rec {
   base = "/log";
   files = {
     exec = "${base}/exec.log";
     cron = "${base}/cron.log";
   };
  };

  # The creation script for the container
  creationScript = ''
    #!${pkgs.bash}/bin/bash

    # Create needed directories
    mkdir -p "/var/cache/dns_updater" "/var/spool/cron/crontabs" "/var/run" "/root" "/tmp"

    # Create the log files
    mkdir -p "${log.base}"
    touch "${log.files.exec}" "${log.files.cron}"

    # Install the roots information to passwd
    echo 'root:x:0:0:root:/root:/bin/bash' > /etc/passwd

    # Copy the cron file
    file_dir="/var/spool/cron/crontabs"
    mkdir -p "$(basename "$file_dir")"
    cp "${cronFile}/cron" "$file_dir/root"
  '';

  # The main cron file
  cronFile = pkgs.writeTextFile {
    name = "cron"; destination = "/cron"; text = ''
      */5 * * * * bash "${pkgs.reference.projects.containers}/build/update-dns/update_dns.sh" >> "${log.files.exec}" 2>&1
    '';
  };

  # Create the main script for the container
  initScript = pkgs.writeScriptBin "start" ''
    #!${pkgs.bash}/bin/bash

    # Import ENVs to proper path
    printenv | grep "KEY\|SSL" > /etc/environment

    # Start cron process
    crond -f -l 0 -L ${log.files.cron} &

    # Tail log file
    tail -fq "${log.files.exec}" &

    # Wait for all processes
    wait
  '';

in pkgs.dockerTools.buildImage {

  # Tags
  name = "${information.repo}/freedns";
  created = information.when;

  # Base Image
  fromImage = baseImage;

  # All the files to copy to the container
  copyToRoot = [];

  # Script to create the system
  runAsRoot = creationScript;

  # The initialisation script
  config.Cmd = [ "tini" "${initScript}/bin/start" ];

}
