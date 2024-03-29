{ pkgs, lib, osConfig, config, ... }:

lib.mkIf osConfig.mine.graphics.enable

(let

  # Links for all the theming that I have setup for me
  linkAllPersonalPackage = [
    # Themes
    (
      (pkgs.functions.listCreateLinks "${pkgs.reference.projects.themes}/collection" ".local/share/themes") //
      (pkgs.functions.listCreateLinks "${pkgs.reference.projects.themes}/openbox" ".local/share/themes")
    )
    # Cursors
    (pkgs.functions.listCreateLinks "${pkgs.reference.projects.cursors}/my-x11-cursors" ".local/share/icons")
    # Icons
    (pkgs.functions.listCreateLinks "${pkgs.reference.projects.icons}/my-icons-collection" ".local/share/icons")
    # Fonts
    { ".local/share/fonts/mine".source = "${pkgs.reference.projects.fonts}/my-custom-fonts"; }
    # Wallpapers
    { ".local/share/backgrounds/mine".source = "${pkgs.reference.projects.images}/wallpapers"; }
  ];

  # Create the link for the default cursor theme
  defaultCursorLink = {
    ".local/share/icons/default/index.theme".source = pkgs.writeTextFile {
      name = "default";
      text = lib.generators.toINI {} {"Icon Theme" = { Inherits = osConfig.mine.graphics.cursor; }; };
    };
  };

  # Link all the packages manuall
  linkAllPackages = let

    # Fonts
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

    # Icons
    iconsList = with pkgs; [
      papirus-icon-theme
    ];

    # Themes
    themesList = with pkgs; [
      gnome.gnome-themes-extra
      cinnamon.mint-themes
    ];

    # The packing function
    packIt = items: original: destination: extraDir:
      lib.forEach items
        (pack:
          pkgs.functions.listCreateLinks
          "${pack}/${original}"
          (if extraDir then "${destination}/${pack.name}" else destination)
        );

  in builtins.concatLists [
    # Fonts
    (packIt fontsList "share/fonts" ".local/share/fonts/system" true)
    # Icons
    (packIt iconsList "share/icons" ".local/share/icons" false)
    # Themes
    (packIt themesList "share/themes" ".local/share/themes" false)
  ];

  # Link vst folders
  linkPossibleVSTs = lib.mkIf osConfig.mine.production.audio {
    ".local/share/vst/zynaddsubfx" = { source = "${pkgs.zyn-fusion}/lib/vst"; };
    ".local/share/vst/lsp" = { source = "${pkgs.lsp-plugins}/lib/vst"; };
  };

in
{

  # Some XDG links
  xdg.configFile = {
    # Link the fontconfig conf file
    "fontconfig/fonts.conf" = { source = "${pkgs.reference.projects.fonts}/fonts.conf"; };
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

    # Configuratio for alacritty
    alacritty = {
      enable = true;
      # All the settings
      settings = pkgs.reference.more.alacritty;
    };

  };

  # All the needed links for the system to have its flair
  home.file = lib.mkMerge (

    # My own links
    linkAllPersonalPackage ++
    # Link to all the packaged files
    linkAllPackages ++
    # Link to custom files
    [ defaultCursorLink ] ++
    # Extra linking for extra functionalities
    [ linkPossibleVSTs ]

  );

})
