{ my, mfunc, pkgs, ... }:
{

  # Games
  home.packages = with pkgs; [
  ] ++
  # amd64 only games
  mfunc.useDefault ((my.arch == my.reference.x64) || (my.arch == my.reference.x86)) [

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

  ] [];

}
