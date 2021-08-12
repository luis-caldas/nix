{ pkgs, ... }:
{

  environment.systemPackages = with pkgs; [

    # Package for locking the screen
    alock

  ];

}
