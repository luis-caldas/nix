{ my, mfunc, pkgs, lib, ... }:
{

  # Set program to change backlight
  programs.light.enable = true;

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
    extensions = [

      "padekgcemlokbadohgkifijomclgjgif" # switchy proxy omega

      "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
      "gcbommkclmclpchllfjekcdonpmejbdp" # https everywhere
      "pkehgijcmpdhfbdbbnkijodmdjhbjlgp" # privacy badger
      "fihnjjcciajhdojfnbdddfaoknhalnja" # i dont care about cookies

      "cnojnbdhbhnkbcieeekonklommdnndci" # search by image
      "aleakchihdccplidncghkekgioiakgal" # h264ify

      "gbmdgpbipfallnflgajpaliibnhdgobh" # json viewer

      # "pddljdmihkpdfpkgmbhdomeeifpklgnm" # vertical tabs

    ] ++
    # Add users extensions
    my.config.graphical.chromium.extensions.common;

    # Extra options using policy
    extraOpts = {
       # Set colour from xresources file
       "BrowserThemeColor" = mfunc.getElementXRes (my.projects.desktop + "/xresources/XResources") "MY_BACKGROUND";
    } //
    my.chromium.policies // my.config.graphical.chromium.policies;

  };

  # Add chromium initial config
  # environment.etc."chromium/master_preferences".text = builtins.toJSON my.chromium.preferences; # chromium needs a patch to read this path

  # Other needed packages
  environment.systemPackages = with pkgs; [

    # Package for locking the screen
    alock

  ];

}
