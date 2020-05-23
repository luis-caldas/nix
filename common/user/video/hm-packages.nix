{ pkgs, ... }:
let
  my = import ../../../config.nix;
  mfunc = import ../../../functions/func.nix;
in
{

  nixpkgs.config.allowUnsupportedSystem = true;

  home.packages = with pkgs; [

    # Basic graphics tools that I use
    
    # Desktop
    openbox
    picom
    conky
    rofi

    # Terminal emulator
    # alacritty
    # kitty
    # termite
    # rxvt-unicode

    # Key reassignment
    xorg.xmodmap
    xorg.xev

    # Functional
    haskellPackages.xmobar

    # Web
    firefox
    electron

    # Visual calculator
    qalculate-gtk

    # Image editing
    gimp
    inkscape

    # Wallpaper
    nitrogen

    # Voip
    mumble

    # Testing
    glxinfo

    # Video Recording
    #obs-studio

    # Video player
    mpv

    # Screeshot
    scrot

  ] ++ 
  mfunc.useDefault my.config.audio [ pavucontrol ] [] ++
  my.config.packages.user.video;

}
