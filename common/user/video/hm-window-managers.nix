{ pkgs, ... }:
let
  my = import ../../../config.nix;
in
{

  xsession.windowManager.xmonad = {
    enable = true;
    extraPackages = haskellPackages: [
      haskellPackages.xmonad-contrib
      haskellPackages.xmonad
    ];
  };

}
