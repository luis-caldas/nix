{ ... }:
{

  # Set my default window manager
  xsession.windowManager.xmonad = {
    enable = true;
    extraPackages = haskellPackages: [
      haskellPackages.xmonad-contrib
      haskellPackages.xmonad
    ];
  };

}
