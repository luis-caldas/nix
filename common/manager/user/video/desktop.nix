{ pkgs, lib, osConfig, config, options, ... }:

lib.mkIf osConfig.mine.graphics.enable

(let

  # Get the main browser
  mainBrowser = (builtins.head osConfig.mine.browser.others).name;

  # Create an object with all the new browser info so it can be referenced
  browsersNewInfo = map (eachBrowser: {
    name = "browser-${eachBrowser.name}";
    path = "${osConfig.mine.browser.name}-${eachBrowser.name}";
  }) osConfig.mine.browser.others;

  # Join the default applications from config with our browser
  defaultApplications = osConfig.mine.graphics.applications // {
    browser = "${(builtins.head browsersNewInfo).name}.desktop";
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
      features = let
        flag = {
          enable = "--enable-features";
          disable = "--disable-features";
        };
        build = inFlag: listItems:
          "${inFlag}=${
            lib.strings.concatStringsSep "," (
              map (inString:
                (builtins.replaceStrings [" "] [""]
                  (pkgs.functions.capitaliseString
                    (builtins.replaceStrings ["-"] [" "] inString)))
              ) listItems
            )
          }";
      in lib.strings.concatStringsSep " " (
        [(build flag.enable osConfig.mine.browser.enableFlags)
        (build flag.disable osConfig.mine.browser.disableFlags)]
      );
    in {
      name = extraBrowserInfo.name;
      value = {
        name = pkgs.functions.capitaliseString (builtins.replaceStrings ["-"] [" "] extraBrowserInfo.name);
        comment = "Browser Customized ${pkgs.functions.capitaliseString eachBrowser.name}";
        exec = ''${osConfig.mine.browser.name} ${features} --class="${extraBrowserInfo.name}" --user-data-dir="${config.xdg.configHome}/${extraBrowserInfo.path}" %U'';
        icon = osConfig.mine.browser.icon;
        terminal = false;
        categories = [ "Network" "WebBrowser" ];
        settings.StartupWMClass = extraBrowserInfo.name;
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
  customElectron = builtins.listToAttrs (map (eachEntry: {
    name = eachEntry.name;
    value = rec {
      name = pkgs.functions.capitaliseString (builtins.replaceStrings ["-"] [" "] eachEntry.name);
      comment = "${name} web page running as an application";
      exec = ''${osConfig.mine.browser.name} --user-data-dir="${config.xdg.configHome}/browser-apps/${eachEntry.name}" --profile-directory="${eachEntry.name}" --app="${eachEntry.url}"'';
      icon = eachEntry.icon;
      terminal = false;
      categories = [ "Network" "WebBrowser" ];
      settings.StartupWMClass = let
        splitString = lib.lists.drop 1 (
          builtins.filter
          (each: !(builtins.elem each [ [] "" ]))
          (lib.strings.split "/" eachEntry.url)
        );
        fixedUrl = builtins.head splitString;
        after = lib.strings.concatStringsSep "_" (lib.lists.drop 1 splitString);
      in "chrome-${fixedUrl}__${after}-${eachEntry.name}";
    };
  }) osConfig.mine.browser.apps);

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
    "org/gnome/shell".favorite-apps = map (each:
      if (builtins.hasAttr each defaultApplications) then
        builtins.getAttr each defaultApplications
      else
        each
    ) osConfig.mine.graphics.favourites;
    "org/gnome/mutter" = {
      dynamic-workspaces = false;
      edge-tiling = true;
      workspaces-only-on-primary = true;
      attach-modal-dialogs = false;
      experimental-features = [ "scale-monitor-framebuffer" ];
    };
    "org/gnome/desktop/interface" = {

      # Cursor
      cursor-theme = osConfig.mine.graphics.cursor.name;
      cursor-size = lib.mkForce osConfig.mine.graphics.cursor.size;

      # Theming
      icon-theme = if osConfig.mine.graphics.dark then
          osConfig.mine.graphics.iconDark
        else
          osConfig.mine.graphics.icon;
      gtk-theme = if osConfig.mine.graphics.dark then
          osConfig.mine.graphics.themeDark
        else
          osConfig.mine.graphics.theme;
      color-scheme = if osConfig.mine.graphics.dark then
          "prefer-dark"
        else
          "prefer-light";

      # Colour
      accent-color = "slate";

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
      remember-app-usage = false;
      privacy-screen = true;
    };
    "org/gnome/desktop/wm/preferences" = {
      num-workspaces = builtins.length osConfig.mine.graphics.workspaces;
      workspace-names = osConfig.mine.graphics.workspaces;
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
    "org/gnome/settings-daemon/plugins/housekeeping" = {
      donation-reminder-enabled = false;
    };
    "org/gnome/shell/app-switcher" = {
      current-workspace-only = true;
    };
    "org/gnome/desktop/remote-desktop/rdp" = {
      screen-share-mode = "extend";
    };

    # Extensions
    "org/gnome/shell" = {
      disable-extension-version-validation = false;
      disable-user-extensions = false;
      disabled-extensions = [];
      enabled-extensions = [
        # Others
        "clipboard-indicator@tudmotu.com"
        "panel-date-format@keiii.github.com"
        "Vitals@CoreCoding.com"
        "dash-to-dock@micxgx.gmail.com"
        "CustomizeClockOnLockScreen@pratap.fastmail.fm"
        "appindicatorsupport@rgcjonas.gmail.com"
        "smart-home@chlumskyvaclav.gmail.com"
      ];
    };

    # Other programs

    "org/gnome/evolution/shell" = {
      prefer-symbolic-icons = "yes";
    };

    "nautilus/icon-view" = {
      captions = [ "size" "none" "none" ];
    };

    "de/haeckerfelix/Shortwave" = {
      background-playback = false;
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

    # Some custom settings
    formatTime = "%H:%M:%S";
    formatDate = "%Y/%m/%d %a %V %Z";
    formatAll = "${formatDate} ${formatTime}";

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
      multi-monitor = false;
      preferred-monitor = -2;
      show-mounts-network = true;
    };

    date-menu-formatter = {
      pattern = "y/MM/dd kk:mm:ss EEE X";
    };

    panel-date-format = {
      format = formatAll;
    };

    customize-clock-on-lockscreen = {
      custom-date-text = formatDate;
      custom-time-text = formatTime;
      custom-style = false;
      remove-hint = true;
      remove-command-output = true;
      command-output-font-color = "";
      date-font-color = "";
      time-font-color = "";
    };

    trayIconsReloaded = {
      icons-limit = 5;
      icon-size = 20;
      icon-brightness = 0;
      icon-contrast = 0;
      icon-margin-horizontal = 5;
      icon-padding-horizontal = 20;
      tray-margin-left = 0;
      tray-margin-right = 0;
    };

    vitals = {
      alphabetize = true;
      fixed-widths = true;
      hide-icons = false;
      icon-style = 1;
      hot-sensors = [
        "_processor_usage_"
        "_memory_allocated_"
        "__temperature_max__"
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

    # Launcher
    launcher = "gtk-launch";

    # Super key
    superKey = "<Super>";

    # Custom list of keybindings
    keybindings = (lib.attrsets.concatMapAttrs (name: value: {
      "${pkgs.functions.capitaliseString name}" = {
        command = "${launcher} ${if (builtins.hasAttr name defaultApplications) then
            builtins.getAttr name defaultApplications
          else
            name}";
        binding = "${superKey}${pkgs.functions.capitaliseString value}";
      };
    }) osConfig.mine.graphics.keybindings)
    # Custom keybindings for the browser
    //
    (builtins.listToAttrs (lib.lists.imap0
      (index: eachBrowser:
        lib.attrsets.nameValuePair
          "Browser ${pkgs.functions.capitaliseString eachBrowser.name}"
          {
            command = "${launcher} ${(builtins.elemAt browsersNewInfo index).name}.desktop";
            binding = "${superKey}${pkgs.functions.capitaliseString eachBrowser.key}";
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
      (genStrRange (builtins.length osConfig.mine.graphics.workspaces))
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
      ) (genStrRange (builtins.length osConfig.mine.graphics.workspaces))) ++
      # Moving workspaces
      (map (eachIndex:
        { name = "move-to-workspace-${eachIndex}"; value = [
          "<Super><Shift>${eachIndex}" "<Super><Shift><Alt>${eachIndex}" "<Control><Shift><Alt>${eachIndex}"
        ]; }
      ) (genStrRange (builtins.length osConfig.mine.graphics.workspaces)))
    );

  })];

  # Add some extra env vars
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";  # Wayland support
    SPICE_NOGRAB = "1";  # No super key grab for spice
    # APPLICATION_UNICODE = "true";  # Enable my own unicode support for the terminal emulators
  };

  # Add theming for qt
  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style.name = lib.strings.toLower (
      if osConfig.mine.graphics.dark then
        osConfig.mine.graphics.themeDark
      else
        osConfig.mine.graphics.theme
    );
  };

  # Add my own custom desktop files
  xdg.desktopEntries = customElectron // newBrowsersDesktops;

  # Set my own default applications
  xdg.mimeApps = {
    enable = true;
    defaultApplications = defaultMIMEs;
  };
  # Allow the file to be forced into place
  xdg.configFile."mimeapps.list".force = true;

  # All the browser extensions links
  home.file = listBrowserExtensionFiles;

})
