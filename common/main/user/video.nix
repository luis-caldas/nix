{ pkgs, lib, config, ... }:

lib.mkIf config.mine.graphics.enable

{

  # Disable all default fonts
  fonts.enableDefaultPackages = lib.mkForce false;
  fonts.fontconfig.defaultFonts.serif = lib.mkForce [];
  fonts.fontconfig.defaultFonts.emoji = lib.mkForce [];
  fonts.fontconfig.defaultFonts.sansSerif = lib.mkForce [];
  fonts.fontconfig.defaultFonts.monospace = lib.mkForce [];

}