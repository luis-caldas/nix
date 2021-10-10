{ my, pkgs, lib, ... }:
let

  # Acquire the Xresources file
  xreFile = builtins.readFile (my.projects.desktop + "/xresources/XResources");
  # Create a list with the items
  xreList = lib.remove "" (lib.splitString " " (builtins.replaceStrings ["\n"] [" "] xreFile));

  # Function to find the index of a element in the list
  getFirstIndex = nameElement:
    let
      genListIndexes = builtins.genList (x: x) (builtins.length xreList);
      foundIndex = lib.findFirst (x: nameElement == (lib.elemAt xreList x)) 0 genListIndexes;
    in
    foundIndex;

  # Extract value after on list
  colourFromXre = lib.elemAt xreList ((getFirstIndex "MY_BACKGROUND") + 1);

in {

  # Set program to change backlight
  programs.light.enable = true;

  # Enable chromium with custom configs
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

    #"ublock-origin"
    #"https-everywhere"
    #"i-dont-care-about-cookies"
    #"foxyproxy-standard"
    #"privacy-badger"
    #"tree-style-tab"
    #"h264ify"
    #"search-by-image"
    #"translate-web-pages"
    # Extensions
    extensions = [
      "gcbommkclmclpchllfjekcdonpmejbdp" # https everywhere
      "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
    ] ++
    # Add users extensions
    my.config.graphical.chromium.extensions;

    # Extra options using policy
    extraOpts = {
       # Set colour from xresources file
       "BrowserThemeColor" = colourFromXre;
    } //
    my.chromium.policies // my.config.graphical.chromium.policies;

  };

  # Other needed packages
  environment.systemPackages = with pkgs; [

    # Package for locking the screen
    alock

  ];

}
