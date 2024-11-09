{ baseImage, information, pkgs, ... }:

###################
# DNS Crypt Proxy #
###################

# DNS server that securely connects to upstream server

let

  # Original config gile
  configPathOg = "${pkgs.reference.projects.containers}/build/dns/dns.toml";

  # New config file path
  configPath = "/dns.toml";

in pkgs.dockerTools.buildImage {

  # Names and tags
  name = "${information.repo}/dns";
  tag = information.tag;

  # Use the base image
  fromImage = baseImage;

  # Needed packages
  copyToRoot = with pkgs; [
    dnscrypt-proxy2
  ];

  # Script to run at the startup
  runAsRoot = ''
    #!${pkgs.bash}/bin/bash
    cp -r "${configPathOg}" "${configPath}"
  '';

  # Initial command for the image
  config.Cmd = with pkgs; [
    "${dnscrypt-proxy2}/bin/dnscrypt-proxy" "-config" "${configPath}"
  ];

}