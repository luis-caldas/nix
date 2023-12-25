{ pkgs, ... }:
{

  # Configure sudo to work the way I want
  security.sudo = {
    enable = true;
    extraConfig = ''
      %wheel	ALL=(ALL:ALL)	NOPASSWD: ALL

      Defaults !mail_always
      Defaults !mail_badpass
      Defaults !mail_no_host
      Defaults !mail_no_perms
      Defaults !mail_no_user
    '';
  };

  # Disable power commands if not super user or on wheel group
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if ((action.id.indexOf("org.freedesktop.login1.") == 0) ||
          (action.id.indexOf("org.freedesktop.upower.") == 0) ||
          (action.id.indexOf("org.freedesktop.udisks.") == 0) ||
          (action.id.indexOf("org.freedesktop.udisks2.") == 0) ||
          (action.id.indexOf("org.freedesktop.consolekit.system.") == 0)) {
        if (subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        } else {
          return polkit.Result.NO;
        }
      }
    });
  '';

  # Configure the SSH client
  programs.ssh = {
    # Disable askpass graphical password program
    askPassword = "";
    # Enable agent
    startAgent = true;
    agentTimeout = "0";
  };

  # Add my custom certificate authority
  security.pki.certificateFiles = [ "${pkgs.reference.projects.pub}/ssl/ca.pem" ];
  # Also set the paths for all the certificates so they stick
  environment.sessionVariables = {
    NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
    SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
    SYSTEM_CERTIFICATE_PATH = "/etc/ssl/certs/ca-bundle.crt";
  };


}
