{ my, lib, config, mfunc, pkgs, modulesPath, ... }:
{

  imports = [ "${modulesPath}/virtualisation/amazon-image.nix" ];
  ec2.hvm = true;

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    kbdInteractiveAuthentication = false;
    permitRootLogin = lib.mkForce "no";
  };

  users.users."${my.config.user.name}".openssh.authorizedKeys.keyFiles = [
    /etc/nixos/ssh/authorized_keys
  ];

  swapDevices = [ { device = "/swapfile"; } ];

  system.stateVersion = "22.05";

}
