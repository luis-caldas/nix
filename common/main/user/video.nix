{ pkgs, lib, config, ... }:

lib.mkIf config.mine.graphics.enable

{

  # Fonts
  fonts.packages = with pkgs; [
    pkgs.reference.more.fonts.package
  ];

  # Disable all default fonts
  fonts.enableDefaultPackages = lib.mkForce false;
  fonts.fontconfig.defaultFonts.serif = lib.mkForce [ pkgs.reference.more.fonts.name ];
  fonts.fontconfig.defaultFonts.sansSerif = lib.mkForce [ pkgs.reference.more.fonts.name ];
  fonts.fontconfig.defaultFonts.monospace = lib.mkForce [ pkgs.reference.more.fonts.name ];
  fonts.fontconfig.defaultFonts.emoji = lib.mkForce [];

  # Theming
  environment.systemPackages = with pkgs; [
    custom.breeze
    gnome-themes-extra papirus-icon-theme
  ];

  # GDM
  programs.dconf.profiles.gdm.databases = [{
    settings."org/gnome/desktop/interface" = {
      cursor-theme = config.mine.graphics.cursor.name;
      cursor-size = lib.gvariant.mkInt32 config.mine.graphics.cursor.size;
      icon-theme = config.mine.graphics.icon;
      gtk-theme = config.mine.graphics.theme;
      #
      clock-show-seconds = true;
      clock-show-weekday = true;
      show-battery-percentage = true;
      #
      font-antialiasing = "subpixel";
      font-hinting = "full";
      font-name = "Sans 10";
      document-font-name = "Sans 10";
      monospace-font-name = "Mono 10";
    };
  }];

}
