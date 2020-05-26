{ pkgs, ... }:
let
  my = import ../../config.nix;
  mfunc = import ../../functions/func.nix;
in
{

  # Simple packages to get any user going
  environment.systemPackages = with pkgs; [

    # Basic
    vim
    git
    tmux

    # Compatibility
    envsubst

  ];

}
