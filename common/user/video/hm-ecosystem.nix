{ my, mfunc, lib, pkgs, upkgs, ... }:
let

  # My own packages
  packages = {
    desktop = builtins.fetchGit "https://github.com/luis-caldas/mydesktop";
    conky   = builtins.fetchGit "https://github.com/luis-caldas/myconky";
    themes  = builtins.fetchGit "https://github.com/luis-caldas/mythemes";
    fonts   = builtins.fetchGit "https://github.com/luis-caldas/myfonts";
    cursors = builtins.fetchGit "https://github.com/luis-caldas/mycursors";
    icons   = builtins.fetchGit "https://github.com/luis-caldas/myicons";
    papes   = builtins.fetchGit "https://github.com/luis-caldas/mywallpapers";
  };

  # Link all the themes
  linkThemes  = (mfunc.listCreateLinks (packages.themes + "/collection") ".local/share/themes") //
                (mfunc.listCreateLinks (packages.themes + "/openbox") ".local/share/themes");
  linkFonts   = (mfunc.listCreateLinks (packages.fonts + "/my-custom-fonts") ".local/share/fonts");
  linkCursors = (mfunc.listCreateLinks (packages.cursors + "/my-x11-cursors") ".local/share/icons");
  linkIcons   = (mfunc.listCreateLinks (packages.icons + "/my-icons-collection") ".local/share/icons");
  linkPapes   = { ".local/share/backgrounds/papes" = { source = (packages.papes + "/papes"); }; };

  # List of default programs
  defaultPrograms = {
    "browser"   = "firefox";
    "directory" = "org.gnome.Nautilus";
    "image"     = "sxiv";
    "pdf"       = "org.gnome.Evince";
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
      # We set the display variable here
      "export DISPLAY=" + eachDisplay.display + "\n" +
      # Scaling variables
      "export GDK_SCALE=" + (toString eachDisplay.scale) + "\n" +
      "export GDK_DPI_SCALE=" + (toString (1.0 / eachDisplay.scale)) + "\n" +
      "export ELM_SCALE=" + (toString eachDisplay.scale) + "\n" +
      "export QT_AUTO_SCREEN_SCALE_FACTOR=" + (toString eachDisplay.scale) + "\n" +
      # Fix for java applications on tiling window managers
      "export _JAVA_AWT_WM_NONREPARENTING=1" + "\n" +
      # Dont blank screen with DPMS
      "xset s off" + "\n" +
      "xset dpms 0 0 0" + "\n" +
      # Boot up numlock
      "numlockx" + " " + (if my.config.system.numlock then "on" else "off") + "\n" +
      # Change Caps to Ctrl
      "remap-caps-to-ctrl" + "\n" +
      # Extra commands from the config to be added
      (builtins.concatStringsSep "\n" eachDisplay.extraCommands) + "\n" +
      # Restore the wallpapers
      "neotrogen restore" + "\n" +
      # Set the lock program to stay listening on lock events
      "xss-lock neolock" + " " + "&" + "\n" +
      # Call the preferred window manager
      my.config.graphical.wm + " " + "&" + "\n" +
      # Wait for all programs to exit
      "wait" + "\n";
    };
  }) my.config.graphical.displays);

  # Create a alias for the neox startx command
  neoxAlias = { neox = packages.desktop + "/programs/init/neox"; };

  # Put all the sets together
  linkSets = linkThemes // linkFonts // linkIcons // linkCursors // linkPapes //
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
      patches = mfunc.listFullFilesInFolder (packages.desktop + "/term/st/patches");
      extraLibs = [ pkgs.xorg.libXcursor pkgs.harfbuzz ];
    };
  };

  # Add suckless tools that have been configured
  home.packages = with pkgs; [
    st
  ];

  # Add custom XResources file
  xresources.extraConfig = builtins.readFile (packages.desktop + "/xresources/XResources");

  # Add xmonad config file
  xsession.windowManager.xmonad.config = (packages.desktop + "/wm/xmonad/xmonad.hs");

  # Some XDG links
  xdg.configFile = {
    # Link the fontconfig conf file
    "fontconfig/fonts.conf" = { source = packages.fonts + "/fonts.conf"; };
    # Link the conky project
    "conky" = { source = packages.conky; };
    # Link the xmobar configs
    "xmobar" = { source = packages.desktop + "/bar/xmobar"; };
    # Force OVMF links to my config folder
    "virt-ovmf" = { source = "${pkgs.OVMF.fd}/FV"; };
  } //
  # Link the created monitor configs
  linkDisplays;

  # Set icons and themes
  gtk.enable = true;
  gtk.iconTheme.name = my.config.graphical.icons;
  gtk.theme.name     = my.config.graphical.theme;

  # Default XDG applications
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    # Directories
    "inode/directory" = [ (defaultPrograms.directory + ".desktop") ];
    # Images
    "image/bmp"                = [ (defaultPrograms.image + ".desktop") ];
    "image/gif"                = [ (defaultPrograms.image + ".desktop") ];
    "image/vnd.microsoft.icon" = [ (defaultPrograms.image + ".desktop") ];
    "image/jpeg"               = [ (defaultPrograms.image + ".desktop") ];
    "image/png"                = [ (defaultPrograms.image + ".desktop") ];
    "image/svg+xml"            = [ (defaultPrograms.image + ".desktop") ];
    "image/tiff"               = [ (defaultPrograms.image + ".desktop") ];
    "image/webp"               = [ (defaultPrograms.image + ".desktop") ];
    # PDF
    "application/pdf"          = [ (defaultPrograms.pdf + ".desktop") ];
    # Browser
    "text/html"                = [ (defaultPrograms.browser + ".desktop") ];
    "x-scheme-handler/http"    = [ (defaultPrograms.browser + ".desktop") ];
    "x-scheme-handler/https"   = [ (defaultPrograms.browser + ".desktop") ];
    "x-scheme-handler/about"   = [ (defaultPrograms.browser + ".desktop") ];
    "x-scheme-handler/unknown" = [ (defaultPrograms.browser + ".desktop") ];
  };

  # Enable firefox and set its configs
  programs.firefox = {
    enable = true;
    profiles.main = {
      settings = {
        "browser.download.dir" = "/home/" + my.config.user.name + "/downloads";
        "browser.download.lastDir" = "/home/" + my.config.user.name + " /downloads";
      } //
      my.firefox //
      (lib.foldr (x: y: x // y) {} my.config.graphical.firefox.settings.extra);
      userChrome  = builtins.readFile (packages.desktop + "/browser/firefox" + "/userChrome.css");
      userContent = builtins.readFile (packages.desktop + "/browser/firefox" + "/userContent.css");
    };
  };

  # Enable chromium (ungoogled) and set its extensions
  #programs.chromium = {
  #  enable = true;
  #  package = upkgs.ungoogled-chromium;
  #  extensions = [];
  #};

  # Add all the acquired link sets to the config
  home.file = linkSets;

}
