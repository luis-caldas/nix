{ pkgs, ... }:
{

  # Add blueman applet
  services.blueman-applet.enable = true;

  # Add a service to manage mpris headset support
  systemd.user.services.mpris-proxy = {
    Unit.Description = "Mpris proxy";
    Unit.After = [ "network.target" "sound.target" ];
    Service.ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
    Install.WantedBy = [ "default.target" ];
  };

}
