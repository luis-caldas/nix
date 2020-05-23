{ ... }:
{

  # Create the sudo group
  users.groups.sudo = {};

  security.sudo.enable = true;
  security.sudo.extraConfig = "%sudo	ALL=(ALL:ALL)	NOPASSWD: ALL";

  # Disable askpass
  programs.ssh.askPassword = "";

}
