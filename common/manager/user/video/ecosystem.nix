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

  # Install all the needed extensions
  listBrowserExtensionFiles = lib.listToAttrs (builtins.concatLists (lib.attrsets.mapAttrsToList
    (name: value: map (eachExt: extensionJson eachExt value.path) value.extensions)
    (lib.attrsets.filterAttrs (name: value: value.extensions != []) osConfig.mine.browser.extensions.others)
  ));

in
{

  # Some XDG links
  xdg.configFile = {
    # Link the fontconfig conf file
    "fontconfig/fonts.conf" = { source = pkgs.reference.projects.fonts + "/fonts.conf"; };
  };

  # Add a service to manage mpris headset support
  services.mpris-proxy.enable = osConfig.mine.bluetooth;

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
      config = pkgs.reference.more.mpv.settings;
    };

  };

  # All the needed links for the system to have its flair
  home.file = lib.mkMerge ([
    linkThemes linkFonts linkPapes
    linkCursors linkIcons
    linkVST
    listBrowserExtensionFiles
  ] ++
  linkSystemFonts ++
  linkSystemIcons ++
  linkSystemThemes);

})
