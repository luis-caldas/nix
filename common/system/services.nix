{ ... }:
let
  my = import ../../config.nix;
in
{

  # SSH mate
  services.openssh.enable = my.config.services.ssh;

  # Docker for my servers
  virtualisation.docker.enable = my.config.services.docker;
  
}
