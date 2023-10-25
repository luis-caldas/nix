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
    most
    gotop
    screen
    neovim
    nix-top
    nix-tree
    trash-cli

    # Network
    wget
    nmap
    socat
    tcpdump

    # Utils
    killall
    moreutils

    # Monitoring
    psmisc
    sysstat

    # Compatibility
    envsubst

    # System monitor
    dmidecode

  ];

}
