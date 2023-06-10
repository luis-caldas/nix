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
  linkInit = { ".myInit".text = let
    scaleString = toString my.config.graphical.display.scale;
  in ''
    #!${pkgs.bash}/bin/bash

    # Add own programs to PATH
    export PATH="''${PATH}:${my.projects.desktop.programs}/public"

    # Fix for java applications on tiling window managers
    export _JAVA_AWT_WM_NONREPARENTING=1

    # Enable moz XInput2 for touch
    export MOZ_USE_XINPUT2=1

    # Boot up numlock

    # Extra commands from the config to be added
    ${ (builtins.concatStringsSep "\n" my.config.graphical.commands) }

    # Set DBus variables
    if test -z "$DBUS_SESSION_BUS_ADDRESS"; then
      eval "$(dbus-launch --exit-with-session --sh-syntax)"
    fi

    # Call the preferred window manager
    Hyprland &

    # Announce graphical session started
    ${pkgs.systemd}/bin/systemctl --user start graphical-session.target

    # Start all possible services
    ${mfunc.useDefault my.config.graphical.conky "${pkgs.systemd}/bin/systemctl --user start neoconky" ""}
    ${pkgs.systemd}/bin/systemctl --user start neodunst

    # Wait for all programs to exit
    wait

    # Announce graphical session stopped
    ${pkgs.systemd}/bin/systemctl --user stop graphical-session.target

    '';
  };

  # Create the default icons file
  linkIconsCursor = { ".local/share/icons/default/index.theme".text = ''
      [Icon Theme]
      Name = default
      Comment = Default theme linker
      Inherits = ${my.config.graphical.cursor},${my.config.graphical.icons}
    '';
  };

  # Create local services
  servicesLocal = {

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
    linkInit linkIconsCursor
    linkVST
    linkSystemIcons
#    listChromeExtensionsFiles
  ] ++
  linkSystemFonts ++
  linkSystemThemes);

in
{

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

  # Add all the acquired link sets to the config
  home.file = linkSets;

}
