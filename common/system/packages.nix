{ pkgs, ... }:
{

  # Simple packages to get any user going
  environment.systemPackages = with pkgs; [

    # Basic
    git
    tmux
    neovim

    # Compatibility
    envsubst

    # System monitor
    dmidecode

  ];

}
