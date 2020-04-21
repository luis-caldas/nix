{ ... }:
let
  configgo = import ../../config.nix;
in
{

   # SSH mate
   services.openssh.enable = configgo.services.ssh;
  
}
