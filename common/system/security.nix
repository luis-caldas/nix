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
      if ((action.id.indexOf("org.freedesktop.login1.power-off") == 0) ||
          (action.id.indexOf("org.freedesktop.login1.power-off-multiple-sessions") == 0) ||
          (action.id.indexOf("org.freedesktop.login1.power-off-ignore-inhibit") == 0) ||
          (action.id.indexOf("org.freedesktop.login1.reboot") == 0) ||
          (action.id.indexOf("org.freedesktop.login1.reboot-multiple-sessions") == 0) ||
          (action.id.indexOf("org.freedesktop.login1.reboot-ignore-inhibit") == 0) ||
          (action.id.indexOf("org.freedesktop.login1.halt") == 0) ||
          (action.id.indexOf("org.freedesktop.login1.halt-multiple-sessions") == 0) ||
          (action.id.indexOf("org.freedesktop.login1.halt-ignore-inhibit") == 0) ||
          (action.id.indexOf("org.freedesktop.login1.suspend") == 0) ||
          (action.id.indexOf("org.freedesktop.login1.suspend-multiple-sessions") == 0) ||
          (action.id.indexOf("org.freedesktop.login1.suspend-ignore-inhibit") == 0) ||
          (action.id.indexOf("org.freedesktop.login1.hibernate") == 0) ||
          (action.id.indexOf("org.freedesktop.login1.hibernate-multiple-sessions") == 0) ||
          (action.id.indexOf("org.freedesktop.login1.hibernate-ignore-inhibit") == 0)) {
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
