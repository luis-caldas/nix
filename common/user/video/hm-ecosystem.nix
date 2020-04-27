{ lib, pkgs, ... }:
let

  my = import ../../../config.nix;
  mfunc = import ../../../functions/func.nix;

  packages = {
    # My own packages
    desktop = builtins.fetchGit "https://github.com/luis-caldas/mydesktop";
    conky   = builtins.fetchGit "https://github.com/luis-caldas/myconky";
    themes  = builtins.fetchGit "https://github.com/luis-caldas/mythemes";
    fonts   = builtins.fetchGit "https://github.com/luis-caldas/myfonts";
    cursors = builtins.fetchGit "https://github.com/luis-caldas/mycursors";
    icons   = builtins.fetchGit "https://github.com/luis-caldas/myicons";
  };

  # Link all the themes
  linkThemes  = (mfunc.listCreateLinks mfunc lib (packages.themes + "/collection") ".local/share/themes") //
                (mfunc.listCreateLinks mfunc lib (packages.themes + "/openbox") ".local/share/themes");
  linkFonts   = (mfunc.listCreateLinks mfunc lib (packages.fonts + "/my-custom-fonts") ".local/share/fonts");
  linkCursors = (mfunc.listCreateLinks mfunc lib (packages.cursors + "/my-x11-cursors") ".local/share/icons");
  linkIcons   = (mfunc.listCreateLinks mfunc lib (packages.icons + "/my-icons-collection") ".local/share/icons");

  # Create the .xinitrc link file
  textXInit = { ".xinitrc" = { text = "exec bash" + " " + packages.desktop + "/entrypoint.bash"; }; };

  # Create the default icons file
  textIconsCursor = { ".local/share/icons/default/index.theme".text = ''
    [Icon Theme]
    Name = default
    Comment = Default theme linker
    Inherits = '' + my.config.graphical.cursor + "," + my.config.graphical.icons; };

  # Check if we should link the custom monitor configuration
  #linkMonitors = mfunc.useDefault my.config.hardware.cmonitor {
  #  "mymonitors" = {
  #    source = ../../../hardware + ("/" + my.config.hardware.folder) + ("/" + "monitors");
  #  };
  #} {};

  # XMonad Configuration
  # linkXMonad = { ".xmonad/xmonad.hs" = { source = packages.desktop + "/wm/xmonad/xmonad.hs"; }; };

  # Put all the sets together
  linkSets = linkThemes // linkFonts // linkCursors // linkIcons // 
             textXInit // textIconsCursor;

in
{

  # Add patches and configs to the suckless tools
  nixpkgs.config.packageOverrides = pkgs:
  {
    st = pkgs.st.override {
      conf = builtins.readFile (packages.desktop + "/suckless/st/config.h");
      patches = mfunc.listFullFilesInFolder mfunc lib (packages.desktop + "/suckless/st/patches");
      extraLibs = [ pkgs.xorg.libXcursor ];
    };
  };

  # Add suckless tools that have been configured
  home.packages = with pkgs; [
    st
    tabbed
    surf
  ];

  # Some XDG links
  xdg.configFile = {
    # Link the fontconfig conf file
    "fontconfig/fonts.conf" = { source = packages.fonts + "/fonts.conf"; };
    # Link the conky project
    "conky" = { source = packages.conky; };
  }; # // 
  # Link the monitor folder if it was set
  # linkMonitors;

  # Add all the acquired link sets to the config
  home.file = linkSets;

}
