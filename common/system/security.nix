{ ... }:
{

  # Create the sudo group
  users.groups.sudo = {};

  # Sudo configs
  security.sudo = {
    enable = true;
    extraConfig = "%sudo	ALL=(ALL:ALL)	NOPASSWD: ALL";
  };

  # Disable power commands if not super user or on wheel group
  security.polkit.extraConfig = ''

    polkit.addRule(function(action, subject) {
      if (action.id.indexOf("org.freedesktop.login1.hibernate") == 0) {
        return polkit.Result.AUTH_ADMIN;
      }
    });

    polkit.addRule(function(action, subject) {
      if (action.id.indexOf("org.freedesktop.login1.power-off") == 0) {
        return polkit.Result.AUTH_ADMIN;
      }
    });

    polkit.addRule(function(action, subject) {
      if (action.id.indexOf("org.freedesktop.login1.reboot") == 0) {
        return polkit.Result.AUTH_ADMIN;
      }
    });

    polkit.addRule(function(action, subject) {
      if (action.id.indexOf("org.freedesktop.login1.suspend") == 0) {
        return polkit.Result.AUTH_ADMIN;
      }
    });

  '';

  programs.ssh = {
    # Disable askpass graphical password program
    askPassword = "";
    # Enable agent
    startAgent = true;
    agentTimeout = "0";
  };

}
