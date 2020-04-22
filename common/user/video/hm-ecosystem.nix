{ lib, pkgs, ... }:
let

  my = import ../../../config.nix;
  mfunc = import ../../../functions/func.nix;

  packages = {
    # My own packages
    desktop = builtins.fetchGit "https://github.com/luis-caldas/mydesktop";
    conky = builtins.fetchGit "https://github.com/luis-caldas/myconky";
    themes = builtins.fetchGit "https://github.com/luis-caldas/mythemes";
    fonts = builtins.fetchGit "https://github.com/luis-caldas/myfonts";
    cursors = builtins.fetchGit "https://github.com/luis-caldas/mycursors";
    icons = builtins.fetchGit "https://github.com/luis-caldas/myicons";
  };

  # Link all the themes
  linkThemes = (mfunc.listCreateLinks lib (packages.themes + "/collection") ".local/share/themes") //
                (mfunc.listCreateLinks lib (packages.themes + "/openbox") ".local/share/themes");
  linkFonts = (mfunc.listCreateLinks lib (packages.fonts + "/my-custom-fonts") ".local/share/fonts");
  linkCursors = (mfunc.listCreateLinks lib (packages.cursors + "/my-x11-cursors") ".local/share/icons");
  linkIcons = (mfunc.listCreateLinks lib (packages.icons + "/my-icons-collection") ".local/share/icons");

  # Create the .xinitrc link file
  textXInit = { ".xinitrc" = { text = "exec bash" + " " + packages.desktop + "/entrypoint.bash"; }; };

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
             textXInit;

in
{

  # Some XDG links
  xdg.configFile = {
    # Link the fontconfig conf file
    "fontconfig/30-mine.conf" = { source = packages.fonts + "/30-my-substitutions.conf"; };
    # Link the conky project
    "conky" = { source = packages.conky; };
  }; # // 
  # Link the monitor folder if it was set
  # linkMonitors;

  # Add all the acquired link sets to the config
  home.file = linkSets;

  # Add patches and configs to the suckless tools
  nixpkgs.config.packageOverrides = pkgs:
  {
    st = pkgs.st.override {
  #    conf = builtins.readFile someFile;
  #    patches = builtins.map pkgs.fetchurl [];
    };
  };

  # Add suckless tools that have been configured
  home.packages = with pkgs; [
    st
    tabbed
    surf
  ];

}
