{ pkgs, ... }:
{

  # Simple packages to get any user going
  environment.systemPackages = with pkgs; [

    # Basic
    vim
    git
    tmux

    # Compatibility
    envsubst

  ];

}
