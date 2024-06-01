{ pkgs, lib, osConfig, ... }:

lib.mkIf (osConfig.mine.graphics.enable && osConfig.mine.games)

{

  # Games
  home.packages = with pkgs; [

    # Emulators
    pcsxr
    pcsx2
    mednafen
    desmume
    dolphinEmu
    cemu

    # Emulator GUI
    mednaffe

    # Retroarch
    (retroarch.override { cores = with libretro; [
      mgba
      citra
      snes9x
      fceumm
      mupen64plus
    ]; })

    # Decompiled
    shipwright
    sm64ex
    (pkgs.writeShellScriptBin
      "sm64ex-coop"
      "exec -a $0 ${sm64ex-coop}/bin/sm64ex $@"
    )  # Coop with different name

    # Proper
    zeroad
    openttd
    xonotic
    clonehero
    hedgewars
    teeworlds
    assaultcube

    # Retro
    crispy-doom
    space-cadet-pinball

    # Sonic
    srb2
    srb2kart

    # Steam
    steam

    # Simulator
    flightgear

    # Gnome
    gnome.aisleriot
    gnome.gnome-mines
    gnome.gnome-sudoku
    gnome.gnome-chess

    # Chess
    gnuchess
    stockfish

    # Managers
    # lutris
    cartridges

    # Streaming
    chiaki

  ] ++

  # amd64 only games
  (if (!pkgs.stdenv.hostPlatform.isAarch) then [

    # Minecraft
    # minecraft  # TODO Broken
    prismlauncher

    # FPS
    openarena

    # N64
    mupen64plus

  ] else []);

}
