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
    noto-fonts-emoji-blob-bin
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
    ".local/share/vst/zynaddsubfx" = { source = "${pkgs.zyn-fusion}/lib/vst"; };
    ".local/share/vst/lsp" = { source = "${pkgs.lsp-plugins}/lib/vst"; };
  } {};

  # GTK Style
  gtkStyle = "";

  # Set the chromium package
  chromiumBrowserPackage = pkgs.chromium.override {
    commandLineArgs = "--force-dark-mode --enable-features=WebUIDarkMode";
  };

  # Function for creating extensions for chromium based browsers
  extensionJson = ext: browserName: let
    configDir = "${config.xdg.configHome}/" + browserName;
    updateUrl = (options.programs.chromium.extensions.type.getSubOptions []).updateUrl.default;
  in with builtins; {
    name = "${configDir}/External Extensions/${ext}.json";
    value.text = toJSON {
      external_update_url = updateUrl;
    };
  };

  # Set browser names
  browserNameMain = "chromium";
  browserNamePersistent = "chromium-persistent";

  # List of applications to be created
  browserApplications = [
    { name = "cloud"; icon = "nextcloud"; url = "https://redirect.caldas.ie"; }
    { name = "whatsapp-web"; icon = "whatsapp"; url = "https://web.whatsapp.com"; }
    { name = "discord-web"; icon = "discord"; url = "https://discord.com/app"; }
    { name = "github-web"; icon = "github"; url = "https://github.com"; }
  ];

  # List of the extensions
  listChromeExtensions = [] ++ my.config.graphical.chromium.extensions.main;
  listChromePersistentExtensions = [] ++ my.config.graphical.chromium.extensions.persistent;

  # Create a list with the extensions
  listChromeExtensionsFiles = lib.listToAttrs (
    # Extensions that exist in the google store
    (map (eachExt: extensionJson eachExt browserNameMain) listChromeExtensions) ++
    (map (eachExt: extensionJson eachExt browserNamePersistent) listChromePersistentExtensions)
  );

  # Put all the sets together
  linkSets = lib.mkMerge ([
    linkThemes linkFonts linkIcons linkCursors linkPapes
    linkVST
    listChromeExtensionsFiles
  ] ++
  linkSystemFonts ++
  linkSystemIcons ++
  linkSystemThemes);

in
{

  # Add my made programs to PATH
  home.sessionPath = [ "${my.projects.desktop.programs}/public" ];
  # Add some extra env vars
  home.sessionVariables = {
    _JAVA_AWT_WM_NONREPARENTING = "1";  # Fix for java applications on tiling window managers
    NIXOS_OZONE_WL = "";  # Ozone wayland remove (still not working with electron)
    APPLICATION_UNICODE = "true";  # Enable my own unicode support for the terminal emulators
  };

  # Some XDG links
  xdg.configFile = {
    # Link the fontconfig conf file
    "fontconfig/fonts.conf" = { source = my.projects.fonts + "/fonts.conf"; };
    # GTK4
    "gtk-4.0/gtk.css" = { text = gtkStyle; };
  };

  # Add extra gtk css for colours
  gtk.gtk3.extraCss = gtkStyle;

  # Set icons and themes
  gtk.enable = true;
  gtk.iconTheme.name = my.config.graphical.icons;
  gtk.theme.name = my.config.graphical.theme;

  # Set cursor
  home.pointerCursor = {
    package = my.projects.cursors;
    gtk.enable = true;
    name = my.config.graphical.cursor;
  };

  # Add theming for qt
  qt.enable = true;
  qt.platformTheme = "gtk";

  # Bluetooth applet
  # Not needed due to gnomes native bluetooth control
  # services.blueman-applet.enable = my.config.bluetooth;

  # Add a service to manage mpris headset support
  services.mpris-proxy.enable = my.config.bluetooth;

  # All gnome configuration
  dconf.settings = let
    prefix = "main";
    default = "df.png";
    wallpapersDir = "${my.projects.wallpapers}/papes";
    firstImage = lib.findFirst (x: lib.hasPrefix prefix x) default (mfunc.listFilesInFolder wallpapersDir);
    backgroundPath = "file://${wallpapersDir}/${firstImage}";
    workspaces = [
      "Main" "Browse" "Mail" "Docs" "Game" "Design" "Web" "Links" "Music"
    ];
  in lib.mkMerge [{
    "org/gnome/desktop/input-sources" = {
      xkb-options = [ "caps:ctrl_modifier" ];
    };
    "org/gnome/desktop/peripherals/touchpad" = {
      tap-to-click = true;
      two-finger-scrolling-enabled = true;
      click-method = "areas";
    };
    "org/gnome/desktop/peripherals/keyboard" = {
      numlock-state = true;
    };
    "org/gnome/shell".favorite-apps = [
      "org.gnome.Terminal.desktop"
      "chromium-browser.desktop"
      "thunderbird.desktop"
      #"codium.desktop"
      "idea-ultimate.desktop"
      "writer.desktop"
      "gimp.desktop"
      "schildichat-desktop.desktop"
      "cloud.desktop"
      #"com.github.eneshecan.WhatsAppForLinux.desktop"
      "spotify.desktop"
    ];
    "org/gnome/mutter" = {
      edge-tiling = true;
      workspaces-only-on-primary = true;
    };
    "org/gnome/desktop/interface" = {
      cursor-size = lib.mkForce 32;
      color-scheme = "prefer-dark";
      enable-hot-corners = false;
      clock-show-seconds = true;
      clock-show-weekday = true;
      font-antialiasing = "subpixel";
      font-hinting = "full";
      show-battery-percentage = true;
      gtk-theme = my.config.graphical.theme;
    };
    "org/gnome/desktop/privacy" = {
      recent-files-max-age = -1;
      remember-recent-files = false;
    };
    "org/gnome/desktop/wm/preferences" = {
      num-workspaces = builtins.length workspaces;
      workspace-names = workspaces;
      button-layout = "menu,appmenu:minimize,maximize,close";
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
    "org/gnome/settings-daemon/plugins/power" = {
      power-button-action = "nothing";
    };
    "org/gnome/shell/app-switcher" = {
      current-workspace-only = true;
    };
    # Extensions
    "org/gnome/shell" = {
      disable-extension-version-validation = false;
      disable-user-extensions = false;
      disabled-extensions = [];
      enabled-extensions = [
        # Official
        "drive-menu@gnome-shell-extensions.gcampax.github.com"
        "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
        # Others
        "clipboard-indicator@tudmotu.com"
        "trayIconsReloaded@selfmade.pl"
        "date-menu-formatter@marcinjakubowski.github.com"
        "Vitals@CoreCoding.com"
        "dash-to-dock@micxgx.gmail.com"
        "RemoveAppMenu@Dragon8oy.com"
        # Disabled
        #"gsconnect@andyholmes.github.io"
        #"window-list@gnome-shell-extensions.gcampax.github.com"
        #"places-menu@gnome-shell-extensions.gcampax.github.com"
        #"mediacontrols@cliffniff.github.com"
        #"arcmenu@arcmenu.com"
        #"mprisLabel@moon-0xff.github.com"
      ];
    };
  }
  # Extensions configuration
  (let
    startPath = "org/gnome/shell/extensions";
    buildFull = wholeSet:
      builtins.listToAttrs (
        map
        (key: { name = "${startPath}/${key}"; value = builtins.getAttr key wholeSet; })
        (builtins.attrNames wholeSet)
      );
  in buildFull {
    arcmenu = {
      application-shortcuts-list = [];
      dash-to-panel-standalone = true;
      default-menu-view = "Categories_List";
      directory-shortcuts-list = [
        ["Documents"  ". GThemedIcon folder-documents-symbolic folder-symbolic folder-documents folder" "ArcMenu_Documents"]
        ["Downloads"  ". GThemedIcon folder-download-symbolic folder-symbolic folder-download folder"   "ArcMenu_Downloads"]
        ["Music"      ". GThemedIcon folder-music-symbolic folder-symbolic folder-music folder"         "ArcMenu_Music"]
        ["Pictures"   ". GThemedIcon folder-pictures-symbolic folder-symbolic folder-pictures folder"   "ArcMenu_Pictures"]
        ["Videos"     ". GThemedIcon folder-videos-symbolic folder-symbolic folder-videos folder"       "ArcMenu_Videos"]
      ];
      enable-menu-hotkey = false;
      extra-categories = [
        (lib.hm.gvariant.mkTuple [1 false]) (lib.hm.gvariant.mkTuple [2 false])
        (lib.hm.gvariant.mkTuple [3 false]) (lib.hm.gvariant.mkTuple [4 false])
      ];
      menu-button-appearance = "Icon_Text";
      menu-layout = "Default";
      pinned-app-list = [];
      power-options = [
        (lib.hm.gvariant.mkTuple [0 false]) (lib.hm.gvariant.mkTuple [1 false])
        (lib.hm.gvariant.mkTuple [2 false]) (lib.hm.gvariant.mkTuple [3 false])
        (lib.hm.gvariant.mkTuple [4 false]) (lib.hm.gvariant.mkTuple [5 false])
        (lib.hm.gvariant.mkTuple [6 false]) (lib.hm.gvariant.mkTuple [7 false])
      ];
      prefs-visible-page = 0;
      show-activities-button = true;
      show-bookmarks = false;
    };
    clipboard-indicator = {
      disable-down-arrow = false;
      display-mode = 0;
      enable-keybindings = false;
      history-size = 1000000;
    };
    dash-to-dock = {
      apply-custom-theme = true;
      disable-overview-on-startup = true;
      hot-keys = false;
      isolate-monitors = false;
      multi-monitor = true;
      show-mounts-network=true;
    };
    date-menu-formatter = {
      pattern = "y/MM/dd kk:mm:ss EEE X";
    };
    trayIconsReloaded = {
      icons-limit = 1;
    };
    vitals= {
      alphabetize = true;
      fixed-widths = true;
      hide-icons = false;
      hot-sensors = [
        "_processor_usage_"
        "_memory_allocated_"
        "__network-rx_max__" "__network-tx_max__"
        "__temperature_avg__" "__temperature_max__"
      ];
      position-in-panel = 1;
      show-fan = false;
      show-network = true;
      show-storage = false;
      show-system = false;
      show-temperature = true;
      show-voltage = false;
      use-higher-precision = false;
    };
    mpris-label = {
      auto-switch-to-most-recent = true;
      extension-index = 20;
      extension-place = "center";
      max-string-length = 20;
      left-padding = 0;
      right-padding = 0;
      first-field = "xesam:artist";
      second-field = "";
      right-click-action = "next-track";
      thumb-backward-action = "none";
      thumb-forward-action = "none";
    };
  })
  # Create custom keybindings
  (let
    startMedia = "org/gnome/settings-daemon/plugins/media-keys";
    keybindingsKey = "custom-keybindings";
    keybindingsPath = "${startMedia}/${keybindingsKey}";
    # Custom list of keybindings
    keybindings = {
      "Terminal" = {
        command = "gnome-terminal";
        binding = "<Super>Return";
      };
      "Browser" = {
        command = "chromium";
        binding = "<Super>N";
      };
      "Browser Persistent" = {
        command = "chromium --user-data-dir=\"${config.xdg.configHome}/${browserNamePersistent}\"";
        binding = "<Super>M";
      };
      "Browser Basic" = {
        command = "chromium --user-data-dir=\"${config.xdg.configHome}/chromium-work\"";
        binding = "<Super>B";
      };
    };
    # Convert that list into dconf
    keybindingsList = let setNow = keybindings; in (map (key:
      { name = key; value = builtins.getAttr key setNow; }
    ) (builtins.attrNames setNow));
    customKeysList = lib.lists.imap0 ( index: item:
      let
        customName = "custom${builtins.toString index}";
      in {
        name = "${keybindingsPath}/${customName}"; value = {
          name = item.name;
          command = item.value.command;
          binding = item.value.binding;
        };
      }
    ) keybindingsList;
    customKeys = builtins.listToAttrs customKeysList;
    # Another entry is needed listing all the created keybindings
    listOfEntryNames = {
      "${startMedia}"."${keybindingsKey}" = map (eachName: "/${eachName}/") (builtins.attrNames customKeys);
    };
    # Join both dconfs into a single one (both the customs and the name list)
    allCustom = customKeys // listOfEntryNames;
  in allCustom)
  # Overwrite keybindings and set my own
  (let
    mapAttrsHelp = attrSetInput:
      map (key: {name = key; value = builtins.getAttr key attrSetInput;}) (builtins.attrNames attrSetInput);
    genStrRange = size:
      map builtins.toString (lib.lists.range 1 size);
  in {
    "org/gnome/shell/keybindings" = builtins.listToAttrs ((let
        simple = {
          focus-active-notification = [];
          toggle-message-tray = [ "<Super>V" ];
        };
      in (mapAttrsHelp simple)) ++
      (map (eachIndex:
        { name = "switch-to-application-${eachIndex}"; value = []; }
      ) (genStrRange (builtins.length workspaces))));
    "org/gnome/settings-daemon/plugins/media-keys" = builtins.listToAttrs ((let
        simple = {
          help = [];
          magnifier = [ "<Alt><Super>Z" ];
        };
      in (mapAttrsHelp simple)));
    "org/gnome/desktop/wm/keybindings" = builtins.listToAttrs ((let
        simple = {
          close = [ "<Super>BackSpace" "<Alt>F4" ];
          activate-window-menu = [ "<Alt>Space" ];
        };
      in (mapAttrsHelp simple)) ++
      # Switching workspaces
      (map (eachIndex:
        { name = "switch-to-workspace-${eachIndex}"; value = [
          "<Super>${eachIndex}" "<Super><Alt>${eachIndex}" "<Control><Alt>${eachIndex}"
        ]; }
      ) (genStrRange (builtins.length workspaces))) ++
      # Moving workspaces
      (map (eachIndex:
        { name = "move-to-workspace-${eachIndex}"; value = [
          "<Super><Shift>${eachIndex}" "<Super><Shift><Alt>${eachIndex}" "<Control><Shift><Alt>${eachIndex}"
        ]; }
      ) (genStrRange (builtins.length workspaces))));
  })];

  # Add my own custom "applications"
  xdg.desktopEntries = {} // (
    # Automatically create the chromium applications from a list
    builtins.listToAttrs (map (eachEntry: {
      name = eachEntry.name;
      value = rec {
        name = mfunc.capitaliseString (builtins.replaceStrings ["-"] [" "] eachEntry.name);
        comment = "${name} web page running as an application";
        exec = ''/usr/bin/env sh -c "chromium --user-data-dir=\\$HOME/.config/browser-apps/${eachEntry.name} --app=${eachEntry.url}"'';
        icon = eachEntry.icon;
        terminal = false;
        categories = [ "Network" "WebBrowser" ];
      };
    }) browserApplications)
  );

  # Home manager programs
  programs = {

    # Enable chromium
    chromium = {
      enable = true;
      package = chromiumBrowserPackage;
    };

    # Enable vscode
    vscode = {
      enable = true;
      package = pkgs.vscodium;
      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
        zhuangtongfa.material-theme
      ];
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
