{ pkgs, lib, osConfig, config, options, ... }:

lib.mkIf osConfig.mine.graphics.enable

(let

  # Links for everything used on my desktop
  linkThemes  = (pkgs.functions.listCreateLinks ("${pkgs.reference.projects.themes}/collection") ".local/share/themes") //
                (pkgs.functions.listCreateLinks ("${pkgs.reference.projects.themes}/openbox") ".local/share/themes");
  linkCursors = (pkgs.functions.listCreateLinks ("${pkgs.reference.projects.cursors}/my-x11-cursors") ".local/share/icons");
  linkIcons   = (pkgs.functions.listCreateLinks ("${pkgs.reference.projects.icons}/my-icons-collection") ".local/share/icons");
  linkFonts   = { ".local/share/fonts/mine" = { source = ("${pkgs.reference.projects.fonts}/my-custom-fonts"); }; };
  linkPapes   = { ".local/share/backgrounds/mine" = { source = ("${pkgs.reference.projects.images}/wallpapers"); }; };

  # Create custom system fonts
  fontsList = with pkgs; [
    iosevka-bin
    (iosevka-bin.override { variant = "aile"; })
    (iosevka-bin.override { variant = "slab"; })
    (iosevka-bin.override { variant = "etoile"; })
    courier-prime
    apl386 bqn386
    sarasa-gothic
    noto-fonts-emoji-blob-bin
  ];
  # Create links from custom fonts
  linkSystemFonts = lib.forEach fontsList (
    pack: (
      pkgs.functions.listCreateLinks
      ("${pack}" + "/share/fonts")
      (".local/share/fonts/system/" + pack.name)
    )
  );

  # Create links from the system themes
  linkSystemIcons = lib.forEach (with pkgs; [
    papirus-icon-theme
  ]) (
    pack: (
      pkgs.functions.listCreateLinks
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
      pkgs.functions.listCreateLinks
      ("${pack}" + "/share/themes")
      ".local/share/themes"
    )
  );

  # Link vst folders
  linkVST = lib.mkIf osConfig.mine.production.audio {
    ".local/share/vst/zynaddsubfx" = { source = "${pkgs.zyn-fusion}/lib/vst"; };
    ".local/share/vst/lsp" = { source = "${pkgs.lsp-plugins}/lib/vst"; };
  };

  # Function for creating extensions for chromium based browsers
  extensionJson = ext: browserName: let
    configDir = "${config.xdg.configHome}/" + browserName;
    updateUrl = (options.programs.chromium.extensions.type.getSubOptions []).updateUrl.default;
  in {
    name = "${configDir}/External Extensions/${ext}.json";
    value.text = builtins.toJSON {
      external_update_url = updateUrl;
    };
  };

  # Set browser names
  browserNameMain = "chromium";
  browserNamePersistent = "chromium-persistent";

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

  # List of the extensions
  listChromeExtensions = [] ++ osConfig.mine.browser.extensions.main;
  listChromePersistentExtensions = [] ++ osConfig.mine.browser.extensions.persistent;

  # Create a list with the extensions
  listChromeExtensionsFiles = lib.listToAttrs (
    # Extensions that exist in the google store
    (map (eachExt: extensionJson eachExt browserNameMain) listChromeExtensions) ++
    (map (eachExt: extensionJson eachExt browserNamePersistent) listChromePersistentExtensions)
  );

  # Autostarting programs and commands
  autoStartPrograms = [
    { name = "nextcloud.autostart"; command = "${pkgs.nextcloud-client}/bin/nextcloud --background"; icon = "nextcloud"; }
  ];
  autoStartApps = builtins.listToAttrs (map
    (eachItem: let
      fixedName = pkgs.functions.capitaliseString (builtins.replaceStrings ["_" "-" "."] [" " " " " "] eachItem.name);
      desktopName = "${eachItem.name}.desktop";
      desktopItem = pkgs.makeDesktopItem rec{
        name = eachItem.name;
        desktopName = fixedName;
        exec = eachItem.command;
        icon = eachItem.icon;
      };
    in {
      name = ".config/autostart/${desktopName}";
      value.source = "${desktopItem}/share/applications/${desktopName}";
    })
    autoStartPrograms);

  # Put all the sets together
  linkSets = lib.mkMerge ([
    linkThemes linkFonts linkPapes
    linkCursors linkIcons
    linkVST
    listChromeExtensionsFiles
  ] ++
  linkSystemFonts ++
  linkSystemIcons ++
  linkSystemThemes);

in
{

  # Add some extra env vars
  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    # APPLICATION_UNICODE = "true";  # Enable my own unicode support for the terminal emulators
  };

  # Some XDG links
  xdg.configFile = {
    # Link the fontconfig conf file
    "fontconfig/fonts.conf" = { source = pkgs.reference.projects.fonts + "/fonts.conf"; };
  };

  # Add theming for qt
  qt = {
    enable = true;
    platformTheme = "gnome";
    style.name = lib.strings.toLower osConfig.mine.graphics.theme;
  };

  # Add a service to manage mpris headset support
  services.mpris-proxy.enable = osConfig.mine.bluetooth;

  # Add my own custom "applications"
  xdg.desktopEntries = {} // (
    # Automatically create the chromium applications from a list
    builtins.listToAttrs (map (eachEntry: {
      name = eachEntry.name;
      value = rec {
        name = pkgs.functions.capitaliseString (builtins.replaceStrings ["-"] [" "] eachEntry.name);
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
      package = pkgs.chromium.override {
        commandLineArgs = "--force-dark-mode --enable-features=WebUIDarkMode";
      };
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
      userSettings = pkgs.reference.more.codium.settings;
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

})
