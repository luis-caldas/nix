{ pkgs, lib, osConfig, ... }:

lib.mkIf osConfig.mine.games

{

  # Games
  home.packages = with pkgs; [
  ] ++
  # amd64 only games
  (if (pkgs.reference.arch != pkgs.reference.arches.arm) then [

    # Dwarf Fortress
    (pkgs.dwarf-fortress-packages.dwarf-fortress-full.override {
      theme = null;
      enableIntro = false;
      enableFPS = true;
      enableDFHack = false;
      enableStoneSense = false;
      enableTWBT = false;
      enableTextMode = true;
    })

  ] else []);

}
