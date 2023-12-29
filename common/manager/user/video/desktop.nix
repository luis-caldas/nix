{ pkgs, lib, osConfig, config, ... }:

lib.mkIf osConfig.mine.graphics.enable

(let

  # Function to create the name for the custom browsers
  createBrowserName = commonName: "browser-${commonName}-custom";

  # Get the name of the main browser
  mainBrowser = createBrowserName (builtins.head (builtins.attrNames osConfig.mine.browser.others));

  # Custom replacement list for the mimes
  replacementList = {
    browser = mainBrowser;
  };

  # Create the massive list of the default applications for everything
  defaultMIMEs = lib.attrsets.zipAttrs (builtins.concatLists (lib.attrsets.mapAttrsToList
    (name: value: let
      # Check for replacements and apply them
      entryName = if builtins.elem name (builtins.attrNames replacementList) then
        "${replacementList."${name}"}.desktop"
      else
        value.entry;
    in
      map
      (mime: { "${mime}" = entryName; })
      value.mimes
    )
    pkgs.reference.more.applications));

  # Create the desktop entries for all the new browsers
  newBrowsersDesktops = (
    # Automatically create the chromium applications from a list
    builtins.listToAttrs (lib.attrsets.mapAttrsToList (eachBrowserName: eachBrowserValue: {
      name = createBrowserName eachBrowserName;
      value = rec {
        name = pkgs.functions.capitaliseString (builtins.replaceStrings ["-"] [" "] eachBrowserName);
        comment = "${name} web page running as an application";
        exec = ''/usr/bin/env sh -c "${osConfig.mine.browser.command} --user-data-dir=\\$HOME/.config/${eachBrowserValue.path}"'';
        icon = "web-browser";
        terminal = false;
        categories = [ "Network" "WebBrowser" ];
      };
    }) osConfig.mine.browser.others)
  );

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
      { name = "spotify-web"; icon = "spotify"; url = "https://open.spotify.com/"; }
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
      };
    }) browserApplications)
  );

in {

  # All gnome configuration
  dconf.settings = let

    # My default background
    backgroundPath = let
      # Prefix of the main wallpaper file
      prefix = "main";
      # Default if the main is not found
      default = "df.png";
      # Directory to all wallpapers
      wallpapersDir = "${pkgs.reference.projects.images}/wallpapers";
      # Find the main file otherwise use the default
      firstImage = lib.findFirst (item: lib.hasPrefix prefix item) default (pkgs.functions.listFilesInFolder wallpapersDir);
    in
      "file://${wallpapersDir}/${firstImage}";

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
    "org/gnome/shell".favorite-apps = with pkgs.reference.more.applications; [
      terminal.entry
      "${mainBrowser}.desktop"
      files.entry
    ];
    "org/gnome/mutter" = {
      edge-tiling = true;
      workspaces-only-on-primary = true;
      experimental-features = [ "scale-monitor-framebuffer" ];
    };
    "org/gnome/desktop/interface" = {
      cursor-size = lib.mkForce 32;
      cursor-theme = osConfig.mine.graphics.cursor;
      icon-theme = osConfig.mine.graphics.icon;
      gtk-theme = osConfig.mine.graphics.theme;
      color-scheme = "prefer-dark";
      enable-hot-corners = false;
      clock-show-seconds = true;
      clock-show-weekday = true;
      font-antialiasing = "subpixel";
      font-hinting = "full";
      show-battery-percentage = true;
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
    keybindings = with pkgs.reference.more.applications; {
      "Terminal" = {
        command = "gtk-launch ${terminal.entry}";
        binding = "<Super>Return";
      };
      "File" = {
        command = "gtk-launch ${files.entry}";
        binding = "<Super>E";
      };
    }
    # Custom keybindings for the browser
    //
    (lib.attrsets.mapAttrs'
      (name: value:
        lib.attrsets.nameValuePair
          "Browser ${pkgs.functions.capitaliseString name}"
          {
            command = "gtk-launch ${createBrowserName name}.desktop";
            binding = "<Super>${value.key}";
          }
      )
      osConfig.mine.browser.others
    );

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

})
