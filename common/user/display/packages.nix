{ pkgs, ... }:
{

  home.packages = with pkgs; [

    # Basic graphics tools that I use
    
    # Desktop
    openbox
    xmobar
    conky
    rofi

    # Testing
    glxinfo
 
    # Video player
    mpv

  ];

}
