{ pkgs, ... }:
let
  configgo = import ../../../config.nix;
in
{

  environment.systemPackages = with pkgs; [

  ] ++ configgo.packages.system.video;

}
