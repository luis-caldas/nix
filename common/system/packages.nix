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
    parallel
    nix-tree

    # Compatibility
    envsubst

    # System monitor
    dmidecode

  ];

}
