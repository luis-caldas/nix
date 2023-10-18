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
    # All should be open source and researched
    extensions = [

      "padekgcemlokbadohgkifijomclgjgif" # switchy proxy omega

      "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
      "pkehgijcmpdhfbdbbnkijodmdjhbjlgp" # privacy badger

      "fnaicdffflnofjppbagibeoednhnbjhg" # floccus bookmarks manager

      "bjilljlpencdcpihofiobpnfgcakfdbe" # clear browsing data

      "cnojnbdhbhnkbcieeekonklommdnndci" # search by image

      "gbmdgpbipfallnflgajpaliibnhdgobh" # json viewer

      "nngceckbapebfimnlniiiahkandclblb" # bitwarden client

      "hkgfoiooedgoejojocmhlaklaeopbecg" # picture in picture

    ] ++
    # Add users extensions
    my.config.graphical.chromium.extensions.common;

    # Extra options using policy
    extraOpts = {} //
    my.chromium.policies.managed // my.config.graphical.chromium.policies;

  };

  # Add recommended policies as well
  environment.etc."chromium/policies/recommended/default.json".text = builtins.toJSON {};
  environment.etc."chromium/policies/recommended/extra.json".text = builtins.toJSON my.chromium.policies.recommended;

  # Add chromium initial config
  # environment.etc."chromium/master_preferences".text = builtins.toJSON my.chromium.preferences; # chromium needs a patch to read this path

  # Other needed packages
  environment.systemPackages = with pkgs; [

    # Package for locking the screen
    xsecurelock
    alock

    # CL info
    clinfo

  ];

}
