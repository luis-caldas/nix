{ my, ... }:
{

  # SSH mate
  services.openssh.enable = my.config.services.ssh;

  # Docker for my servers
  virtualisation.docker.enable = my.config.services.docker;

  # Virtualization
  virtualisation.libvirtd = {
    enable = true;
    onBoot = "ignore";
    qemuOvmf = true;
  };

  # DBus session sockets
  services.dbus.socketActivated = true;

}
