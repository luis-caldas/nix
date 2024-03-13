{ pkgs, lib, osConfig, ... }:

lib.mkIf (osConfig.mine.graphics.enable && osConfig.mine.games)

{

  # Games
  home.packages = with pkgs; [

    # Emulators
    pcsxr
    pcsx2
    citra
    mednafen
    desmume
    dolphinEmu
    cemu
    yuzu-mainline

    # Emulator GUI
    mednaffe

    # Retroarch
    (retroarch.override { cores = with libretro; [
      mgba
      snes9x
      fceumm
      mupen64plus
    ]; })

    # Decompiled
    pkgs.unstable.shipwright  # TODO 24.05
    # sm64ex
    sm64ex-coop

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
    pkgs.unstable.srb2      # TODO 24.05
    pkgs.unstable.srb2kart  # TODO 24.05

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
    minecraft
    prismlauncher

    # FPS
    openarena

    # N64
    mupen64plus

  ] else []);

}
