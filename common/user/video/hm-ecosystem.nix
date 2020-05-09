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

  # Create the file containg the selected theme and icons
  themeString = "" +
    "gtk-icon-theme-name = " + my.config.graphical.icons + "\n" +
    "gtk-theme-name = " + my.config.graphical.theme;
  fileTheme = { 
    "gtk-3.0/settings.ini".text = "" + "[Settings]" + "\n" + themeString;
  };

  # Create the .xinitrc link file
  textXInit = { ".xinitrc" = { 
    text = "" + 
      ''xrdb -load "''${HOME}""/.Xresources"'' + "\n" +  
      "exec bash" + " " + packages.desktop + "/entrypoint.bash" + "\n";
  }; };

  # Create the default icons file
  textIconsCursor = { ".local/share/icons/default/index.theme".text = ''
    [Icon Theme]
    Name = default
    Comment = Default theme linker
    Inherits = '' + my.config.graphical.cursor + "," + my.config.graphical.icons; };

  # Create a script for each monitor
  linkDisplays = builtins.listToAttrs (map (eachDisplay: { 
    name = "my-displays" + "/display" + (builtins.replaceStrings [":"] ["-"] eachDisplay.display);
    value = { text = "" +
      "export DISPLAY=" + eachDisplay.display + "\n" +
      "export GDK_SCALE=" + (toString eachDisplay.scale) + "\n" +
      "export GDK_DPI_SCALE=" + (toString (1.0 / eachDisplay.scale)) + "\n" +
      "export ELM_SCALE=" + (toString eachDisplay.scale) + "\n" +
      "export QT_AUTO_SCREEN_SCALE_FACTOR=" + (toString eachDisplay.scale) + "\n" +
      (builtins.concatStringsSep "\n" eachDisplay.extraCommands) + "\n" + # add the users custom command
      "nitrogen --restore" + "\n" +
      my.config.graphical.wm + " " + "&" + "\n" +
      "wait" + "\n" ;};
  }) my.config.graphical.displays);

  # Create a alias for the neox startx command
  neoxAlias = { neox = packages.desktop + "/programs/init/neox"; };

  # XMonad Configuration
  # linkXMonad = { ".xmonad/xmonad.hs" = { source = packages.desktop + "/wm/xmonad/xmonad.hs"; }; };

  # Put all the sets together
  linkSets = linkThemes // linkFonts // linkCursors // linkIcons // # linkXMonad // 
             textXInit // textIconsCursor;

in
{

  # Add my bash aliases
  programs.bash.shellAliases = neoxAlias;

  # Add patches and configs to the suckless tools
  nixpkgs.config.packageOverrides = pkgs:
  {
    st = pkgs.st.override {
      conf = builtins.readFile (packages.desktop + "/term/st/config.h");
      patches = mfunc.listFullFilesInFolder mfunc lib (packages.desktop + "/term/st/patches");
      extraLibs = [ pkgs.xorg.libXcursor ];
    };
  };

  # Add suckless tools that have been configured
  home.packages = with pkgs; [
    st
  ];

  # Some XDG links
  xdg.configFile = {
    # Link the fontconfig conf file
    "fontconfig/fonts.conf" = { source = packages.fonts + "/fonts.conf"; };
    # Link the conky project
    "conky" = { source = packages.conky; };
    # Link the xmobar configs
    #"xmobar" = { source = packages.desktop + "/bar/xmobar"; };
  } // 
  # Link the file with the gtk theme configurations
  fileTheme //
  # Link the created monitor configs
  linkDisplays;

  # Add all the acquired link sets to the config
  home.file = linkSets;

}
