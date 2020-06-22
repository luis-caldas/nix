{ my, ... }:
{

  # SSH mate
  services.openssh.enable = my.config.services.ssh;

  # Docker for my servers
  virtualisation.docker.enable = my.config.services.docker;

  # DBus session sockets
  services.dbus.socketActivated = true;

}
