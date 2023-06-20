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
  linkSystemIcons = lib.forEach (with pkgs; [
    papirus-icon-theme
  ]) (
    pack: (
      mfunc.listCreateLinks
      ("${pack}" + "/share/icons")
      ".local/share/icons"
    )
  );

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
    # Extra commands from the config to be executed
    ${ (builtins.concatStringsSep "\n" my.config.graphical.commands) }
  ''; };

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
    linkInit
    linkVST
#    listChromeExtensionsFiles
  ] ++
  linkSystemFonts ++
  linkSystemIcons ++
  linkSystemThemes);

in
{

#  # Add my made programs to PATH
  home.sessionPath = [ "${my.projects.desktop.programs}/public" ];
  # Add some extra env vars
  home.sessionVariables = {
    # Fix for java applications on tiling window managers
    _JAVA_AWT_WM_NONREPARENTING = "1";
    NIXOS_OZONE_WL = "1";
  };

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
  gtk.theme.name = my.config.graphical.theme;

  # Set cursor
  home.pointerCursor = {
    package = my.projects.cursors;
    gtk.enable = true;
    name = my.config.graphical.cursor;
    size = 24;
  };

  # Add extra gtk css for colours
  gtk.gtk3.extraCss = gtkStyle;

  # Add theming for qt
  qt.enable = true;
  qt.platformTheme = "gtk";

  # All gnome configuration
  dconf.settings = let
    prefix = "main";
    default = "df.png";
    wallpapersDir = "${my.projects.wallpapers}/papes";
    firstImage = lib.findFirst (x: lib.hasPrefix prefix x) default (mfunc.listFilesInFolder wallpapersDir);
    backgroundPath = "file://${wallpapersDir}/${firstImage}";
  in {
    "org/gnome/desktop/input-sources" = {
      xkb-options = [ "caps:ctrl_modifier" ];
    };
    "org/gnome/desktop/peripherals/touchpad" = {
      tap-to-click = true;
      two-finger-scrolling-enabled = true;
    };
    "org/gnome/shell".favorite-apps = [
      "spotify.desktop"
    ];
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      enable-hot-corners = false;
      clock-show-seconds = true;
      clock-show-weekday = true;
      font-antialiasing = "subpixel";
      font-hinting = "full";
      gtk-theme = my.config.graphical.theme;
    };
    "org/gnome/desktop/privacy" = {
      recent-files-max-age = -1;
      remember-recent-files = false;
    };
    "org/gnome/desktop/wm/preferences" = {
      workspace-names = [
        "Main" "Browse" "Mail" "Docs" "Game" "Design" "Web" "Links" "Music"
      ];
    };
    "org/gnome/desktop/background" = {
      picture-uri = backgroundPath;
      picture-uri-dark = backgroundPath;
    };
    "org/gnome/desktop/interface" = {
      font-name = "Sans 10";
      document-font-name = "Sans 10";
      monospace-font-name = "Mono 11";
    };
    "org/gnome/desktop/screensaver" = {
      picture-uri = backgroundPath;
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      name = "Terminal";
      command = "kitty";
      binding = "<Super>Return";
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

  # Add all the acquired link sets to the config
  home.file = linkSets;

}
