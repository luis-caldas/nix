{ my, mfunc, upkgs, config, pkgs, ... }:
{

  nixpkgs.config.allowUnsupportedSystem = true;

  home.packages = with pkgs; [

    # Basic graphics tools that I use

    # Desktop
    openbox
    conky
    rofi

    # XDG
    dconf
    gnome-themes-extra

    # Monitors
    arandr

    # File manager
    gnome3.nautilus

    # Desktop lock
    xss-lock

    # Electronics
    kicad
    logisim

    # Key reassignment
    xorg.xev

    # Functional
    haskellPackages.xmobar

    # Web
    electron

    # Calculator
    gnome3.gnome-calculator

    # Image editing
    gimp
    inkscape

    # Document viewer
    evince

    # Image viewer
    sxiv

    # Email
    thunderbird

    # Wallpaper
    nitrogen

    # Voip
    mumble

    # Testing
    gource
    glxinfo

    # Virtualization
    spice-gtk

    # Video player
    mpv

    # Casting
    catt

    # Screeshot
    scrot

    # Streaming
    streamlink

  ] ++
  # Unsable packages
  [

    # Window Composer
    upkgs.picom

  ] ++
  mfunc.useDefault my.config.x86_64 [

    # Video Apps
    upkgs.obs-studio
    upkgs.blender
    upkgs.looking-glass-client

  ] [] ++
  mfunc.useDefault my.config.audio [

    # Audio Control
    pavucontrol

  ] [] ++
  mfunc.useDefault my.config.graphical.production [

    # Music production
    jack2
    cadence
    reaper
    calf
    guitarix
    linuxsampler
    qsampler

  ] [];
}
