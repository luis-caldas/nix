{ pkgs, lib, osConfig, config, options, ... }:

lib.mkIf osConfig.mine.graphics.enable

(let

  # Get the main browser
  mainBrowser = (builtins.head osConfig.mine.browser.others).name;

  # Create an object with all the new browser info so it can be referenced
  browsersNewInfo = map (eachBrowser: {
    name = "browser-${eachBrowser.name}";
    path = "${osConfig.mine.browser.command}-${eachBrowser.name}";
  }) osConfig.mine.browser.others;

  # List of default apps for the desktop
  defaultApplications = {
    terminal = "Alacritty.desktop";
    browser = "${(builtins.head browsersNewInfo).name}.desktop";
    email = "thunderbird.desktop";
    text = "org.gnome.TextEditor.desktop";
    audio = "io.bassi.Amberol.desktop";
    video = "memento.desktop";
    image = "org.gnome.Loupe.desktop";
    files = "org.gnome.Nautilus.desktop";
    archive = "org.gnome.FileRoller.desktop";
    pdf = "org.gnome.Evince.desktop";
    calendar = "org.gnome.Calendar.desktop";
    iso = "gnome-disk-image-mounter.desktop";
  };

  # Create the massive list of the default applications for everything
  defaultMIMEs = lib.attrsets.zipAttrs (builtins.concatLists (lib.attrsets.mapAttrsToList
    (name: value:
      map
      (mime: { "${mime}" = defaultApplications."${name}"; })
      value
    )
    pkgs.reference.more.mimes));

  # Create the desktop entries for all the new browsers
  newBrowsersDesktops = (
    # Automatically create the chromium applications from a list
    builtins.listToAttrs (lib.lists.imap0 (index: eachBrowser: let
      extraBrowserInfo = builtins.elemAt browsersNewInfo index;
    in {
      name = extraBrowserInfo.name;
      value = {
        name = pkgs.functions.capitaliseString (builtins.replaceStrings ["-"] [" "] extraBrowserInfo.name);
        comment = "Browser Customized ${pkgs.functions.capitaliseString eachBrowser.name}";
        exec = ''/usr/bin/env sh -c "${osConfig.mine.browser.command} --user-data-dir=${config.xdg.configHome}/${extraBrowserInfo.path}"'';
        icon = "web-browser";
        terminal = false;
        categories = [ "Network" "WebBrowser" ];
        settings.StartupWMClass = "chromium-browser (${config.xdg.configHome}/${extraBrowserInfo.path})";
      };
    }) osConfig.mine.browser.others)
  );

  # Set all the custom extensions for the browsers
  listBrowserExtensionFiles = let

    # Function for creating extensions for chromium based browsers
    extensionJson = ext: browserName: let
      configDir = "${config.xdg.configHome}/${browserName}";
      updateUrl = (options.programs.chromium.extensions.type.getSubOptions []).updateUrl.default;
    in {
      name = "${configDir}/External Extensions/${ext}.json";
      value.text = builtins.toJSON {
        external_update_url = updateUrl;
      };
    };

  in lib.listToAttrs (builtins.concatLists (lib.lists.imap0
    (index: eachExtendedBrowser: map (eachExtension:
      extensionJson eachExtension (builtins.elemAt browsersNewInfo index).path
      # Add the default extensions to the per each system ones
    ) eachExtendedBrowser.extensions)
    (
      # Filter all the browsers with empty extension lists
      builtins.filter
      (eachBrowser: eachBrowser.extensions != [])
      osConfig.mine.browser.others
    )
  ));

  # Create custom electron applications for all my used websites
  customElectron = let

    # List of applications to be created
    browserApplications = [
      { name = "deck"; icon = "nextcloud"; url = "https://redirect.caldas.ie"; }
      { name = "notes"; icon = "nextcloud"; url = "https://redirect.caldas.ie"; }
      { name = "jellyfin-web"; icon = "jellyfin"; url = "https://redirect.caldas.ie"; }
      { name = "whatsapp-web"; icon = "whatsapp"; url = "https://web.whatsapp.com"; }
      { name = "discord-web"; icon = "discord"; url = "https://discord.com/app"; }
      { name = "github-web"; icon = "github"; url = "https://github.com"; }
      { name = "chess-web"; icon = "chess"; url = "https://chess.com"; }
      { name = "spotify-web"; icon = "spotify"; url = "https://open.spotify.com"; }
      { name = "defence-forces"; icon = "knavalbattle"; url = "https://irishdefenceforces.workvivo.com"; }
    ];

  in (
    # Automatically create the chromium applications from a list
    builtins.listToAttrs (map (eachEntry: {
      name = eachEntry.name;
      value = rec {
        name = pkgs.functions.capitaliseString (builtins.replaceStrings ["-"] [" "] eachEntry.name);
        comment = "${name} web page running as an application";
        exec = ''/usr/bin/env sh -c "${osConfig.mine.browser.command} --user-data-dir=\\$HOME/.config/browser-apps/${eachEntry.name} --app=${eachEntry.url}"'';
        icon = eachEntry.icon;
        terminal = false;
        categories = [ "Network" "WebBrowser" ];
        settings.StartupWMClass = let
          fixedUrl = lib.lists.last (lib.strings.split "/" eachEntry.url);
        in "chrome-${fixedUrl}__-Default";
      };
    }) browserApplications)
  );

in {

  # All gnome configuration
  dconf.settings = let

    # My default background
    backgroundPaths = let
      # Naming of files
      files = {
        light = "main-light.png";
        dark = "main-dark.png";
      };
      # Directory to all wallpapers
      wallpapersDir = "${pkgs.reference.projects.images}/wallpapers";
      # Function to generate the file url
      genUrlPath = imagePath: "file://${wallpapersDir}/${imagePath}";
    in
      { light = genUrlPath files.light;
        dark  = genUrlPath files.dark;
      };

    # My workspaces
    workspaces = [
      "Main" "Browse" "Mail" "Docs" "Game" "Design" "Web" "Links" "Music"
    ];

  in lib.mkMerge [

  # All my configuration that can be easily set
  {

    "org/gnome/desktop/input-sources" = {
      sources = map (eachInput: (lib.hm.gvariant.mkTuple ["xkb" eachInput])) osConfig.mine.system.layout;
      xkb-options = [ "caps:ctrl_modifier" ];
    };
    "org/gnome/desktop/peripherals/touchpad" = {
      tap-to-click = true;
      two-finger-scrolling-enabled = true;
      click-method = "areas";
    };
    "org/gnome/desktop/peripherals/keyboard" = {
      numlock-state = osConfig.mine.graphics.numlock;
    };
    "org/gnome/shell".favorite-apps = with defaultApplications; [
      terminal
      browser
      files
    ];
    "org/gnome/mutter" = {
      edge-tiling = true;
      workspaces-only-on-primary = true;
      experimental-features = [ "scale-monitor-framebuffer" ];
    };
    "org/gnome/desktop/interface" = {

      # Cursor
      cursor-size = lib.mkForce 32;

      # Theming
      cursor-theme = osConfig.mine.graphics.cursor;
      icon-theme = osConfig.mine.graphics.icon;
      gtk-theme = osConfig.mine.graphics.theme;
      color-scheme = "prefer-dark";

      # Bar
      enable-hot-corners = false;
      clock-show-seconds = true;
      clock-show-weekday = true;
      show-battery-percentage = true;

      # Fonts
      font-antialiasing = "subpixel";
      font-hinting = "full";
      font-name = "Sans 10";
      document-font-name = "Sans 10";
      monospace-font-name = "Mono 11";

    };
    "org/gnome/desktop/search-providers" = {
      disable-external = true;
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
      picture-uri = backgroundPaths.light;
      picture-uri-dark = backgroundPaths.dark;
      show-desktop-icons = true;
    };
    "org/gnome/desktop/screensaver" = {
      picture-uri = backgroundPaths.dark;
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
        # Others
        "clipboard-indicator@tudmotu.com"
        "panel-date-format@keiii.github.com"
        "Vitals@CoreCoding.com"
        "dash-to-dock@micxgx.gmail.com"
      ];
    };

  }

  # Configure the extensions
  (let
    # Path to the extensions
    startPath = "org/gnome/shell/extensions";
    # Build all the items using the previous path
    buildFull = wholeSet:
      builtins.listToAttrs (
        map
        (key: { name = "${startPath}/${key}"; value = builtins.getAttr key wholeSet; })
        (builtins.attrNames wholeSet)
      );
    # The entire configuration
  in buildFull {

    clipboard-indicator = {
      display-mode = 0;
      cache-size = 128;
      history-size = 256;
      move-item-first = true;
      disable-down-arrow = false;
      enable-keybindings = false;
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

    panel-date-format = {
      format = "%Y/%m/%d %H:%M:%S %a %z";
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

  # Get my custom keybindings
  (let

    # Paths for the configurations
    startMedia = "org/gnome/settings-daemon/plugins/media-keys";
    keybindingsKey = "custom-keybindings";
    keybindingsPath = "${startMedia}/${keybindingsKey}";

    # Custom list of keybindings
    keybindings = with defaultApplications; {
      "Terminal" = {
        command = "gtk-launch ${terminal}";
        binding = "<Super>Return";
      };
      "File" = {
        command = "gtk-launch ${files}";
        binding = "<Super>E";
      };
    }
    # Custom keybindings for the browser
    //
    (builtins.listToAttrs (let
      # List with the keys for the browsers
      browserKeys = [
        "N"  # Main
        "M"  # Persistent
        "B"  # Normal
        "G"  # Other
      ];
    in lib.lists.imap0
      (index: eachBrowser:
        lib.attrsets.nameValuePair
          "Browser ${pkgs.functions.capitaliseString eachBrowser.name}"
          {
            command = "gtk-launch ${(builtins.elemAt browsersNewInfo index).name}.desktop";
            binding = "<Super>${builtins.elemAt browserKeys index}";
          }
      )
      osConfig.mine.browser.others
    ));

    # Convert custom list into proper dconf
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

  # Overwriting keybindings and setting alternatives
  (let

    # Create a list of given size
    genStrRange = size:
      map builtins.toString (lib.lists.range 1 size);

  in {

    "org/gnome/shell/keybindings" = {
        focus-active-notification = [];
        toggle-message-tray = [ "<Super>V" ];
    } //
    # Change all the switch application keybindings
    builtins.listToAttrs (
      map
        (eachIndex:
        { name = "switch-to-application-${eachIndex}"; value = []; })
      (genStrRange (builtins.length workspaces))
    );

    # Media keys reassignment
    "org/gnome/settings-daemon/plugins/media-keys" = {
      help = [];
      magnifier = [ "<Alt><Super>Z" ];
    };

    # Window manager keybindings
    "org/gnome/desktop/wm/keybindings" = {
      close = [ "<Super>BackSpace" "<Alt>F4" ];
      activate-window-menu = [ "<Alt>Space" ];
      # Fix window switching
      switch-applications = [];
      switch-applications-backward = [];
      switch-windows = [ "<Alt>Tab" ];
      switch-windows-backward = [ "<Shift><Alt>Tab" ];
    } //
    # Workspace specific parts
    builtins.listToAttrs (

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
      ) (genStrRange (builtins.length workspaces)))
    );

  })];

  # Add some extra env vars
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    # APPLICATION_UNICODE = "true";  # Enable my own unicode support for the terminal emulators
  };

  # Add theming for qt
  qt = {
    enable = true;
    platformTheme = "gnome";
    style.name = lib.strings.toLower osConfig.mine.graphics.theme;
  };

  # Add my own custom desktop files
  xdg.desktopEntries = customElectron // newBrowsersDesktops;

  # Set my own default applications
  xdg.mimeApps = {
    enable = true;
    defaultApplications = defaultMIMEs;
  };

  # All the browser extensions links
  home.file = listBrowserExtensionFiles;

})
