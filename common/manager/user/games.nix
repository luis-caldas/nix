{ pkgs, lib, osConfig, ... }:

lib.mkIf osConfig.mine.games

{

  # Games
  home.packages = with pkgs; [
  ] ++
  # AMD64 only games
  (if (!pkgs.stdenv.hostPlatform.isAarch) then [

    # Dwarf Fortress  # BUG Broken
    # (pkgs.dwarf-fortress-packages.dwarf-fortress-full.override {
    #   theme = null;
    #   enableIntro = false;
    #   enableFPS = true;
    #   enableDFHack = false;
    #   enableStoneSense = false;
    #   enableTWBT = false;
    #   enableTextMode = true;
    # })

  ] else []);

}
