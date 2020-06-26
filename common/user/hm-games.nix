{ pkgs, ... }:
{

  nixpkgs.config.allowUnfree = true;

  # Games
  home.packages = with pkgs; [

    # Dwarf Fortress
    (pkgs.dwarf-fortress-packages.dwarf-fortress-full.override {
      theme = null;
      enableIntro = false;
      enableFPS = true;
      enableDFHack = false;
      enableTWBT = false;
      enableTextMode = true;
    })

  ];

}
