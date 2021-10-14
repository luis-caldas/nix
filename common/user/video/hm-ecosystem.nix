{ my, mfunc, lib, pkgs, mpkgs, config, options, ... }:
let

  # Link all the themes
  linkThemes  = (mfunc.listCreateLinks (my.projects.themes + "/collection") ".local/share/themes") //
                (mfunc.listCreateLinks (my.projects.themes + "/openbox") ".local/share/themes");
  linkCursors = (mfunc.listCreateLinks (my.projects.cursors + "/my-x11-cursors") ".local/share/icons");
  linkIcons   = (mfunc.listCreateLinks (my.projects.icons + "/my-icons-collection") ".local/share/icons");
  linkFonts   = { ".local/share/fonts/mine" = { source = (my.projects.fonts + "/my-custom-fonts"); }; };
  linkPapes   = { ".local/share/backgrounds/papes" = { source = (my.projects.wallpapers + "/papes"); }; };

  # Create custom system fonts
  fontsList = with pkgs; [
    iosevka-bin
    (iosevka-bin.override { variant = "aile"; })
    (iosevka-bin.override { variant = "slab"; })
    (iosevka-bin.override { variant = "etoile"; })
    font-awesome
    sarasa-gothic
  ];
  # Create links from custom fonts
  linkSystemFonts = lib.forEach fontsList (
    pack: (
      mfunc.listCreateLinks
      ("${pack}" + "/share/fonts")
      (".local/share/fonts/system/" + pack.name)
    )
  );

  # Create links from the system themes
  linkSystemIcons = mfunc.listCreateLinks
  ("${pkgs.cinnamon.mint-y-icons}" + "/share/icons")
  ".local/share/icons";

  # Create themes from the system themes
  linkSystemThemes = mfunc.listCreateLinks
  ("${pkgs.cinnamon.mint-themes}" + "/share/themes")
  ".local/share/themes";

  # Link vst folders
  linkVST = mfunc.useDefault my.config.graphical.production.audio {
    "./.vst/zynaddsubfx" = { source = "${pkgs.zyn-fusion}" + "/lib/vst"; };
  } {};

  # List of default programs
  defaultPrograms = {
    "browser"   = "chromium";
    "directory" = "org.gnome.Nautilus";
    "image"     = "sxiv";
    "pdf"       = "org.gnome.Evince";
  };

  # Create the .xinitrc link file
  textXInit = { ".xinitrc" = {
    text = "" +
      ''xrdb -load "''${HOME}""/.Xresources"'' + "\n" +
      "exec bash" + " " + my.projects.desktop + "/entrypoint.bash" + "\n";
  }; };

  # Create the default icons file
  textIconsCursor = { ".local/share/icons/default/index.theme".text = ''
    [Icon Theme]
    Name = default
    Comment = Default theme linker
    Inherits = '' + my.config.graphical.cursor + "," + my.config.graphical.icons + "\n";
  };

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
      # Enable moz XInput2 for touch
      "export MOZ_USE_XINPUT2=1" + "\n" +
      # Dont blank screen with DPMS
      "xset s off" + "\n" +
      "xset dpms 0 0 0" + "\n" +
      # Unclutter normally if the cursor is idle
      "unclutter --timeout 10 --jitter 5 --ignore-buttons 4,5,6,7 --start-hidden --fork" + " " + "&" + "\n" +
      # Set unclutter to remove cursor on touch
      (mfunc.useDefault my.config.graphical.touch ("unclutter --hide-on-touch --fork" + " " + "&" + "\n") "") +
      # Boot up numlock
      "numlockx" + " " + (if my.config.system.numlock then "on" else "off") + "\n" +
      # Change Caps to Ctrl
      "remap-caps-to-ctrl" + "\n" +
      # Start bluetooth if present
      (mfunc.useDefault my.config.bluetooth ("blueman-applet" + " " + "&" + "\n") "") +
      # Extra commands from the config to be added
      (builtins.concatStringsSep "\n" eachDisplay.extraCommands) + "\n" +
      # Restore the wallpapers
      "neotrogen restore" + "\n" +
      # Start window compositor
      "neopicom" + " " + "&" + "\n" +
      # Set the lock program to stay listening on lock events
      "xss-lock neolock" + " " + "&" + "\n" +
      # Call the preferred window manager
      my.config.graphical.wm + " " + "&" + "\n" +
      # Wait for all programs to exit
      "wait" + "\n";
    };
  }) my.config.graphical.displays);

  # Create a alias for the neox startx command
  neoxAlias = { neox = my.projects.desktop + "/programs/init/neox"; };

  # Function for creating extensions for chromium based browsers
  extensionJson = ext: browserName:
  let
    configDir = "${config.xdg.configHome}/" + browserName;
    updateUrl = (options.programs.chromium.extensions.type.getSubOptions "").updateUrl.default;
  in
    with builtins; {
      name = "${configDir}/External Extensions/${ext}.json";
      value.text = toJSON ({
        external_update_url = updateUrl;
      });
    };

  # Set browser names
  browserNameMain = "chromium";
  browserNamePersistent = "chromium-persistent";

  # List of the extensions
  listChromeExtensions = [
    "elidgjfpciimeeeoeneeiifkmhadhkeh" # clean all
  ] ++ my.config.graphical.chromium.extensions.main;
  listChromePersistentExtensions = [] ++ my.config.graphical.chromium.extensions.persistent;

  # Create a list with the extensions
  listChromeExtensionsFiles = lib.listToAttrs (
    (map (eachExt: extensionJson eachExt browserNameMain) listChromeExtensions) ++
    (map (eachExt: extensionJson eachExt browserNamePersistent) listChromePersistentExtensions)
  );

  # Put all the sets together
  linkSets = lib.mkMerge ([
    linkThemes linkFonts linkIcons linkCursors linkPapes
    textXInit textIconsCursor
    linkVST
    linkSystemIcons linkSystemThemes
    listChromeExtensionsFiles
  ] ++ linkSystemFonts);

in
{

  # Add my bash aliases
  programs.bash.shellAliases = neoxAlias;

  # Add st to the home packages with my patches and config
  home.packages = with pkgs; [
    (st.override {
      conf = builtins.readFile (my.projects.desktop + "/term/st/config.h");
      patches = mfunc.listFullFilesInFolder (my.projects.desktop + "/term/st/patches");
      extraLibs = [ pkgs.xorg.libXcursor pkgs.harfbuzz ];
    })
  ];

  # Add custom XResources file
  xresources.extraConfig = builtins.readFile (my.projects.desktop + "/xresources/XResources");

  # Add xmonad config file
  xsession.windowManager.xmonad.config = (my.projects.desktop + "/wm/xmonad/xmonad.hs");

  # Some XDG links
  xdg.configFile = {
    # Link the fontconfig conf file
    "fontconfig/fonts.conf" = { source = my.projects.fonts + "/fonts.conf"; };
    # Link the conky project
    "conky" = { source = my.projects.conky; };
    # Link the xmobar configs
    "xmobar" = { source = my.projects.desktop + "/bar/xmobar"; };
    # Force OVMF links to my config folder
    "virt-ovmf" = { source = "${pkgs.OVMF.fd}/FV"; };
  } //
  # Link the created monitor configs
  linkDisplays;

  # Set icons and themes
  gtk.enable = true;
  gtk.iconTheme.name = my.config.graphical.icons;
  gtk.theme.name     = my.config.graphical.theme;

  # Add theming for qt
  qt.enable = true;
  qt.platformTheme = "gtk";

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

  # Enable chromium
  programs.chromium.enable = true;

  # Add all the acquired link sets to the config
  home.file = linkSets;

}
