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
    courier-prime
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
    "./.vst/zynaddsubfx" = { source = "${pkgs.zyn-fusion}/lib/vst"; };
    "./.vst/lsp" = { source = "${pkgs.lsp-plugins}/lib/vst"; };
  } {};

  # List of default programs
  defaultPrograms = {
    "browser"   = "chromium";
    "directory" = "org.gnome.Nautilus";
    "image"     = "sxiv";
    "pdf"       = "org.gnome.Evince";
  };

  # GTK Style
  gtkStyle = let
    colourExtBg = mfunc.getElementXRes ("${my.projects.desktop.xresources}/XResources") "MY_COLOUR_0";
    colourExtFg = mfunc.getElementXRes ("${my.projects.desktop.xresources}/XResources") "MY_FOREGROUND";
  in ''
    @define-color accent_color ${colourExtBg};
    @define-color accent_bg_color ${colourExtBg};
    @define-color accent_fg_color ${colourExtFg};
  '';

  # Create the .xinitrc link file
  textXInit = { ".xinitrc".text = let
    scaleString = toString my.config.graphical.display.scale;
  in ''
    #!${pkgs.bash}/bin/bash

    # Set XOrg variables
    ${pkgs.systemd}/bin/systemctl --user set-environment DISPLAY="''${DISPLAY}"
    ${pkgs.systemd}/bin/systemctl --user set-environment XAUTHORITY="''${XAUTHORITY}"
    ${pkgs.systemd}/bin/systemctl --user set-environment XDG_SESSION_ID="''${XDG_SESSION_ID}"

    # Add own programs to PATH
    export PATH="''${PATH}:${my.projects.desktop.programs}/public"

    # Try to import new systemd variable
    NEW_SCALE="$(${pkgs.systemd}/bin/systemctl --user show-environment | grep NEW_SCALE | cut -d"=" -f2)"

    # Set default scaling variables
    export GDK_SCALE="${scaleString}"

    # Check if new scaling variable was set and if it was, override scaling
    if [ -n "$NEW_SCALE" ]; then
      export GDK_SCALE="''${NEW_SCALE}"
    fi

    # Ceil the scale and save its original value
    ceil_scale="$(awk '{printf("%d\n",$0+=$0<0?0:0.999)}' <<< "''${GDK_SCALE}")"
    export TARGET_SCALE="''${GDK_SCALE}"
    export GDK_SCALE="''${ceil_scale}"

    # Export defaults
    export DEFAULT_XORG_DPI=96
    export DEFAULT_XORG_CURSOR_SIZE=24

    # Get the DPI scale
    dpiScale="$(awk "BEGIN { printf \"%f\n\",1.0/''${GDK_SCALE} }")"
    export GDK_DPI_SCALE="''${dpiScale}"

    # Update more scaling variables
    export ELM_SCALE="''${GDK_SCALE}"
    export QT_AUTO_SCREEN_SCALE_FACTOR=1

    # Export the scaling to systemd
    ${pkgs.systemd}/bin/systemctl --user set-environment GDK_SCALE="''${GDK_SCALE}"
    ${pkgs.systemd}/bin/systemctl --user set-environment TARGET_SCALE="''${TARGET_SCALE}"

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

    # Set X Dpi
    new_dpi="$(awk "BEGIN { printf \"%f\n\",''${DEFAULT_XORG_DPI}*''${GDK_SCALE} }")"
    xrandr --dpi "''${new_dpi}"

    # Set cursor size
    new_cursor_size=$(( DEFAULT_XORG_CURSOR_SIZE * GDK_SCALE ))
    export XCURSOR_SIZE="''${new_cursor_size}"

    # Extra commands from the config to be added
    ${ (builtins.concatStringsSep "\n" my.config.graphical.display.extraCommands) }

    # Restore the wallpapers
    neotrogen restore

    # Set DBus variables
    if test -z "$DBUS_SESSION_BUS_ADDRESS"; then
      eval "$(dbus-launch --exit-with-session --sh-syntax)"
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
    ${mfunc.useDefault my.config.graphical.conky "${pkgs.systemd}/bin/systemctl --user start neoconky" ""}
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

    # Conky
    neoconky = {
      Unit = {
        Description = "Conky system monitor";
        Requires = "graphical-session.target";
        After = "graphical-session.target";
      };
      Service = {
        Restart = "on-failure";
        ExecStart = let
        textFile = pkgs.writeTextFile {
          name = "neoconky"; executable = true;
          text = ''
            #!${pkgs.bash}/bin/bash
            source /etc/profile
            "${pkgs.conky}/bin/conky" -c "${my.projects.conky}/conky.lua"
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
    updateUrl = (options.programs.chromium.extensions.type.getSubOptions []).updateUrl.default;
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
    # GTK4
    "gtk-4.0/gtk.css" = { text = gtkStyle; };
  };

  # Set icons and themes
  gtk.enable = true;
  gtk.iconTheme.name = my.config.graphical.icons;
  gtk.theme.name = "Adwaita-dark";

  # Add extra gtk css for colours
  gtk.gtk3.extraCss = gtkStyle;

  # Add theming for qt
  qt.enable = true;
  qt.platformTheme = "gtk";

  # Set theme color
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

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

  # Home manager programs
  programs = {

    # Enable chromium
    chromium = {
      enable = true;
      package = pkgs.chromium.override {
        commandLineArgs = "--force-dark-mode --enable-features=WebUIDarkMode";
      };
    };

    # Enable vscode
    vscode = {
      enable = true;
      package = pkgs.vscodium;
      extensions = let
        custom = [
          (pkgs.vscode-utils.buildVscodeMarketplaceExtension {
            mktplcRef = {
              name = "Material-theme";
              publisher = "zhuangtongfa";
              version = "3.15.2";
              sha256 = "sha256-6YB6Te9rQo9WKfUZZ5eenqoRdk5lKRYftYkmUIpoFRU=";
            };
            meta = with lib; {
              changelog = "https://marketplace.visualstudio.com/items/zhuangtongfa.Material-theme/changelog";
              description = "Atom's iconic One Dark theme, and one of the most installed themes for VS Code!";
              downloadPage = "https://marketplace.visualstudio.com/items?itemName=zhuangtongfa.Material-theme";
              homepage = "https://github.com/Binaryify/OneDark-Pro";
              license = licenses.mit;
            };
          })
          (pkgs.vscode-utils.buildVscodeMarketplaceExtension {
            mktplcRef = {
              name = "explicit-folding";
              publisher = "zokugun";
              version = "0.21.0";
              sha256 = "0kzfrzmvjadg4wq4imgb3m2h81rm5nrcn1nyz8j1993qz6559d4h";
            };
            meta = with lib; {
              changelog = "https://marketplace.visualstudio.com/items/zokugun.explicit-folding/changelog";
              description = "This extension lets you manually control how and where to fold your code.";
              downloadPage = "https://marketplace.visualstudio.com/items?itemName=zokugun.explicit-folding";
              homepage = "https://github.com/zokugun/vscode-explicit-folding";
              license = licenses.mit;
            };
          })
        ];
      in [
        pkgs.vscode-extensions.jnoortheen.nix-ide
      ] ++ custom;
      haskell = {
        enable = true;
        hie.enable = false;
      };
      userSettings = {
        "workbench.colorTheme" = "One Dark Pro";
        "editor.fontFamily" = "Monospace";
        "workbench.preferredDarkColorTheme" = "One Dark Pro";
        "oneDarkPro.vivid" = true;
        "oneDarkPro.bold" = true;
        "telemetry.telemetryLevel" = "off";
        "editor.fontLigatures" = true;
        "files.trimTrailingWhitespace" = true;
        "keyboard.dispatch" = "keyCode";
        "terminal.integrated.shellIntegration.showWelcome" = false;
        "workbench.startupEditor" = "none";
        "update.mode" = "none";
        "explicitFolding.rules" = {
          "*" = {
              "begin" = "{{{";
              "end" = "}}}";
          };
        };
      };
    };

    # Enable mpv with config
    mpv = {
      enable = true;
      config = {
        profile = "gpu-hq";
        force-window = true;
        ytdl-format = "bestvideo+bestaudio";
        video-sync = "display-resample";
        framedrop = "vo";
        gpu-context = "auto";
        spirv-compiler = "auto";
      };
    };

  };

  # Add all the created services
  systemd.user.services = servicesLocal;

  # Enable redshift
  services.redshift = {
    enable = true;
    latitude = my.config.system.location.latitude;
    longitude = my.config.system.location.longitude;
  };

  # Add all the acquired link sets to the config
  home.file = linkSets;

}
