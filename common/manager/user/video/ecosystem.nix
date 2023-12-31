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

      # Window decoration
      settings.window = {
        decorations = "None";
        padding = {
          x = 32;
          y = 32;
        };
        opacity = 0.95;
      };

      # Colours theme
      settings.colors = {
        # Default colors
        primary = {
          background = "#000000";
          foreground = "#ffffff";
        };
        # Normal colors
        normal = {
          black   = "#000000";
          red     = "#cd0000";
          green   = "#00cd00";
          yellow  = "#cdcd00";
          blue    = "#0000ee";
          magenta = "#cd00cd";
          cyan    = "#00cdcd";
          white   = "#e5e5e5";
        };
        # Bright colors
        bright = {
          black   = "#7f7f7f";
          red     = "#ff0000";
          green   = "#00ff00";
          yellow  = "#ffff00";
          blue    = "#5c5cff";
          magenta = "#ff00ff";
          cyan    = "#00ffff";
          white   = "#ffffff";
        };
      };

    };

  };

  # All the needed links for the system to have its flair
  home.file = lib.mkMerge (

    # My own links
    linkAllPersonalPackage ++
    # Link to all the packaged files
    linkAllPackages ++
    # Extra linking for extra functionalities
    [ linkPossibleVSTs ]

  );

})
