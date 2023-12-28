{ pkgs, ... }:
{

  # Add my made programs to PATH
  home.sessionPath = [ "${pkgs.reference.projects.desktop}/programs/public" ];

}