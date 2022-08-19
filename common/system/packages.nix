{ pkgs, ... }:
{

  # Simple packages to get any user going
  environment.systemPackages = with pkgs; [

    # Basic
    bc
    git
    tmux
    htop
    less
    gotop
    screen
    neovim
    nix-top
    parallel
    nix-tree
    trash-cli

    # Utils
    killall

    # Compatibility
    envsubst

    # System monitor
    dmidecode

  ];

}
