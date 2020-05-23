{ pkgs, ... }:
let
  my = import ../../../config.nix;
in
{

  environment.systemPackages = with pkgs; [];

}
