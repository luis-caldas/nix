{ pkgs, lib, osConfig, ... }:

lib.mkIf (osConfig.mine.graphics.enable && osConfig.mine.games)

{

  # Games
  home.packages = with pkgs; [

    # Emulators
    (lib.lowPrio pcsx2)
    mednafen
    desmume
    dolphin-emu
    cemu

    # Emulator GUI
    mednaffe

    # Retroarch
    (retroarch.withCores (cores: with cores; [
      mgba
      citra
      snes9x
      fceumm
      mupen64plus
      swanstation
    ]))

    # Decompiled
    shipwright
    _2ship2harkinian
    sm64ex
    sm64coopdx

    # Proper
    zeroad
    openttd
    xonotic
    clonehero
    hedgewars
    teeworlds
    assaultcube

    # Retro
    space-cadet-pinball

    # Sonic
    srb2
    srb2kart

    # Steam
    steam

    # Simulator
    # flightgear  # Not needed

    # Gnome
    aisleriot
    gnome-mines
    gnome-chess
    gnome-sudoku
    gnome-mahjongg

    # Chess
    gnuchess
    stockfish

    # Managers
    # lutris
    cartridges

    # Streaming
    chiaki

    # Switch
    ns-usbloader

  ] ++

  # amd64 only games
  (if (!pkgs.stdenv.hostPlatform.isAarch) then [

    # Minecraft
    prismlauncher

    # FPS
    openarena

    # N64
    mupen64plus

  ] else []);

}
