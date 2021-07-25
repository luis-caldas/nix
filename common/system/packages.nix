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
    trash-cli

    # Files
    ntfs-3g

    # Compatibility
    envsubst

    # System monitor
    dmidecode

  ];

}
