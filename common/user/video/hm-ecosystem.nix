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
    (nerdfonts.override { fonts = [ "Iosevka" ]; })
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
  linkSystemThemes = lib.forEach (with pkgs; [
    gnome.gnome-themes-extra
    cinnamon.mint-themes
  ]) (
    pack: (
      mfunc.listCreateLinks
      ("${pack}" + "/share/themes")
      ".local/share/themes"
    )
  );

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
  textXInit = { ".xinitrc".text = let
    scaleString = toString my.config.graphical.display.scale;
    scaleStringDPI = toString (1.0 / my.config.graphical.display.scale);
  in ''
    #!${pkgs.bash}/bin/bash

    # Set XOrg variables
    ${pkgs.systemd}/bin/systemctl --user set-environment DISPLAY="''${DISPLAY}"
    ${pkgs.systemd}/bin/systemctl --user set-environment XAUTHORITY="''${XAUTHORITY}"
    ${pkgs.systemd}/bin/systemctl --user set-environment XDG_SESSION_ID="''${XDG_SESSION_ID}"

    # Add own programs to PATH
    export PATH="''${PATH}:${my.projects.desktop.programs}/public"

    # Try to import new systemd variable
    ${pkgs.systemd}/bin/systemctl --user import-environment NEW_SCALE

    # Set default scaling variables
    export GDK_SCALE="${scaleString}"
    export GDK_DPI_SCALE="${scaleStringDPI}"

    # Check if new scaling variable was set and if it was, override scaling
    if [ -n "$NEW_SCALE" ]; then
      dpiScale=$(awk "BEGIN { print "1.0 / ''${NEW_SCALE}" }")
      export GDK_SCALE="''${NEW_SCALE}"
      export GDK_DPI_SCALE="''${dpiScale}"
    fi

    # Update more scaling variables
    export ELM_SCALE="''${GDK_SCALE}"
    export QT_AUTO_SCREEN_SCALE_FACTOR=1

    # Export the scaling to systemd
    ${pkgs.systemd}/bin/systemctl --user set-environment GDK_SCALE="''${GDK_SCALE}"

    # Fix for java applications on tiling window managers
    export _JAVA_AWT_WM_NONREPARENTING=1

    # Enable moz XInput2 for touch
    export MOZ_USE_XINPUT2=1

    # Dont blank screen with DPMS
    ${pkgs.xorg.xset}/bin/xset s off
    ${pkgs.xorg.xset}/bin/xset dpms 0 0 0

    # Load the proper xresources
    "${pkgs.xorg.xrdb}/bin/xrdb" -load "''${HOME}/.Xresources"

    # Boot up numlock
    ${ "numlockx" + " " + (if my.config.system.numlock then "on" else "off") }

    # Change Caps to Ctrl
    reneocapstoctrl

    # Extra commands from the config to be added
    ${ (builtins.concatStringsSep "\n" my.config.graphical.display.extraCommands) }

    # Restore the wallpapers
    neotrogen restore

    # Set DBus variables
    if test -z "$DBUS_SESSION_BUS_ADDRESS"; then
      eval $(dbus-launch --exit-with-session --sh-syntax)
    fi

    # Update DBus environment
    if command -v dbus-update-activation-environment >/dev/null 2>&1; then
      dbus-update-activation-environment DISPLAY XAUTHORITY
    fi

    # Call the preferred window manager
    ${my.config.graphical.wm} &

    # Announce graphical session started
    ${pkgs.systemd}/bin/systemctl --user start graphical-session.target

    # Start all possible services
    ${pkgs.systemd}/bin/systemctl --user start xlock
    ${pkgs.systemd}/bin/systemctl --user start clipster
    ${pkgs.systemd}/bin/systemctl --user start unclutter
    ${mfunc.useDefault my.config.graphical.touch "${pkgs.systemd}/bin/systemctl --user start unclutter-touch" ""}
    ${mfunc.useDefault my.config.graphical.compositor "${pkgs.systemd}/bin/systemctl --user start neopicom" ""}
    ${pkgs.systemd}/bin/systemctl --user start neodunst

    # Wait for all programs to exit
    wait

    # Announce graphical session stopped
    ${pkgs.systemd}/bin/systemctl --user stop graphical-session.target

    '';
  };

  # Create the default icons file
  textIconsCursor = { ".local/share/icons/default/index.theme".text = ''
      [Icon Theme]
      Name = default
      Comment = Default theme linker
      Inherits = ${my.config.graphical.cursor},${my.config.graphical.icons}
    '';
  };

  # Create local services
  servicesLocal = {

    # Lock screen service
    xlock = {
      Unit = {
        Description = "XServer lock listener";
        Requires = "graphical-session.target";
        After = "graphical-session.target";
      };
      Service = {
        Restart = "on-failure";
        ExecStart = let
        textFile = pkgs.writeTextFile {
          name = "neolock"; executable = true;
          text = ''
            #!${pkgs.bash}/bin/bash
            source /etc/profile
            "${pkgs.systemd}/bin/systemctl" --user import-environment XDG_SESSION_ID
            "${pkgs.xss-lock}/bin/xss-lock" -s "''${XDG_SESSION_ID}" -- "${my.projects.desktop.programs}/public/neolock"
          '';
        }; in "${textFile}";
      };
    };

    # Clipboard service
    clipster = {
      Unit = {
        Description = "Clipboard manager";
        Requires = "graphical-session.target";
        After = "graphical-session.target";
      };
      Service = {
        Restart = "on-failure";
        ExecStart = let
        textFile = pkgs.writeTextFile {
          name = "clipster"; executable = true;
          text = ''
            #!${pkgs.bash}/bin/bash
            source /etc/profile
            "${pkgs.systemd}/bin/systemctl" --user import-environment XDG_SESSION_ID
            "${pkgs.clipster}/bin/clipster" -d
          '';
        }; in "${textFile}";
      };
    };

    # Default unclutter program
    unclutter = {
      Unit = {
        Description = "Unclutter desktop";
        Requires = "graphical-session.target";
        After = "graphical-session.target";
      };
      Service = {
        Restart = "on-failure";
        ExecStart = "${pkgs.unclutter-xfixes}/bin/unclutter --timeout 10 --jitter 5 --ignore-buttons 4,5,6,7";
      };
    };

    # Dunst notification system
    neodunst = {
      Unit = {
        Description = "Neodunst notification system";
        Conflicts = "dunst.service";
        Requires = "graphical-session.target";
        After = "graphical-session.target";
      };
      Service = {
        Restart = "on-failure";
        ExecStart = let
        textFile = pkgs.writeTextFile {
          name = "neodunst"; executable = true;
          text = ''
            #!${pkgs.bash}/bin/bash
            source /etc/profile
            "${pkgs.systemd}/bin/systemctl" --user import-environment GDK_SCALE
            "${my.projects.desktop.programs}/public/neodunst"
          '';
        }; in "${textFile}";
      };
    };

    # Picom window compositor
    neopicom = {
      Unit = {
        Description = "Neopicom window compositor";
        Requires = "graphical-session.target";
        After = "graphical-session.target";
      };
      Service = {
        Restart = "on-failure";
        ExecStart = let
        textFile = pkgs.writeTextFile {
          name = "neopicom"; executable = true;
          text = ''
            #!${pkgs.bash}/bin/bash
            source /etc/profile
            "${my.projects.desktop.programs}/public/neopicom"
          '';
        }; in "${textFile}";
      };
    };

  } //
  # Uncluter + touch support
  mfunc.useDefault my.config.graphical.touch {
    unclutter-touch = {
      Unit = {
        Description = "Unclutter desktop on touch";
        Requires = "graphical-session.target";
        After = "graphical-session.target";
      };
      Service = {
        Restart = "on-failure";
        ExecStart = "${pkgs.unclutter-xfixes}/bin/unclutter --hide-on-touch";
      };
    };
  } {};

  # Create a alias for the neox startx command
  neoxAlias = {
    neox = "${my.projects.desktop.programs}/init/neox";
    neo2x = "${my.projects.desktop.programs}/init/neox 2";
  };

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
    linkSystemIcons
    listChromeExtensionsFiles
  ] ++
  linkSystemFonts ++
  linkSystemThemes);

in
{

  # Add my bash aliases
  programs.bash.shellAliases = neoxAlias;

  # Add st to the home packages with my patches and config
  home.packages = with pkgs; [
    (st.override {
      conf = builtins.readFile ("${my.projects.desktop.term}/st/config.h");
      patches = mfunc.listFullFilesInFolder ("${my.projects.desktop.term}/st/patches");
      extraLibs = [ pkgs.xorg.libXcursor pkgs.harfbuzz ];
    })
  ];

  # Add custom XResources file
  xresources.extraConfig = builtins.readFile ("${my.projects.desktop.xresources}/XResources");

  # Add xmonad config file
  xsession.windowManager.xmonad.config = ("${my.projects.desktop.wm}/xmonad/xmonad.hs");

  # Some XDG links
  xdg.configFile = {
    # Link the fontconfig conf file
    "fontconfig/fonts.conf" = { source = my.projects.fonts + "/fonts.conf"; };
    # Link the conky project
    "conky" = { source = my.projects.conky; };
  };

  # Set icons and themes
  gtk.enable = true;
  gtk.iconTheme.name = my.config.graphical.icons;
  gtk.theme.name     = my.config.graphical.theme;

  # Add extra gtk css for colours
  gtk.gtk3.extraCss = let
    colourExt = mfunc.getElementXRes ("${my.projects.desktop.xresources}/XResources") "MY_COLOUR_0";
  in ''
    @define-color theme_selected_fg_color ${colourExt};
    @define-color theme_selected_bg_color ${colourExt};

    *:selected{
        background-color: @theme_selected_bg_color;
    }

    *.view:selected {
        background-color: @theme_selected_bg_color;
    }

    textview selection {
        background-color: @theme_selected_bg_color;
    }

    selection {
        background-color: @theme_selected_bg_color;
     }

    menu menuitem:hover,
    .menu menuitem:hover {
         background-color: @theme_selected_bg_color;
    }

    switch:checked {
       background-color: @theme_selected_bg_color;
    }

    notebook > header.top > tabs > tab:checked {
        box-shadow: inset 0 -3px  @theme_selected _bg_color;
    }
  '';

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
  programs.chromium = {
    enable = true;
    package = pkgs.chromium.override {
      commandLineArgs = "--disable-remote-fonts --force-dark-mode --enable-features=WebUIDarkMode";
    };
  };

  # Add all the created services
  systemd.user.services = servicesLocal;

  # Add all the acquired link sets to the config
  home.file = linkSets;

}
