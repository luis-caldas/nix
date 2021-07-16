{ ... }:
{

  # Create the sudo group
  users.groups.sudo = {};

  # Sudo configs
  security.sudo = {
    enable = true;
    extraConfig = "%sudo	ALL=(ALL:ALL)	NOPASSWD: ALL";
  };

  programs.ssh = {
    # Disable askpass graphical password program
    askPassword = "";
    # Enable agent
    startAgent = true;
    agentTimeout = "0";
  };

}
