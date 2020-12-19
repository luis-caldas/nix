{ my, mfunc, pkgs, ... }:
{

  # Games
  home.packages = with pkgs; [
  ] ++
  # amd64 only games
  mfunc.useDefault my.config.x86_64 [

    # Dwarf Fortress
    (pkgs.dwarf-fortress-packages.dwarf-fortress-full.override {
      theme = null;
      enableIntro = false;
      enableFPS = true;
      enableDFHack = false;
      enableTWBT = false;
      enableTextMode = true;
    })

  ] [];

}
