{ pkgs, lib, config, ... }:

lib.mkIf config.mine.graphics.enable

{

  # Set program to change backlight
  programs.light.enable = true;

  # Enable weylus
  programs.weylus.enable = true;
  programs.weylus.users = [ config.mine.user.name ];

  # Enable chromium custom configs
  programs.chromium = {

    # Enable chromium
    enable = true;

    # Default sarch provider
    defaultSearchProviderSearchURL = "https://duckduckgo.com/" +
      "?kav=1&kp=-2&k1=-1&kk=-1&kaj=m&kak=-1&" +
      "kax=-1&kaq=-1&kap=-1&kao=-1&kau=-1&kae=d&" +
      "q={searchTerms}";
    defaultSearchProviderSuggestURL = "https://ac.duckduckgo.com" +
    "/ac/?q={searchTerms}&type=list";

    # Extensions all browsers
    # All should be open source and researched
    extensions = config.mine.browser.common;

    # Extra options using policy
    extraOpts = pkgs.reference.more.chromium.policies.managed // config.mine.browser.policies;

  };

  # Enable widevine on chromium
  nixpkgs.config.chromium.enableWideVine = true;

  # Add recommended policies as well
  environment.etc."chromium/policies/recommended/default.json".text = builtins.toJSON {};
  environment.etc."chromium/policies/recommended/extra.json".text = builtins.toJSON pkgs.reference.more.chromium.policies.recommended;

}
