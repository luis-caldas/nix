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

  # Create docker subnet
  system.activationScripts.dockerSubnet = let
    docker = config.virtualisation.oci-containers.backend;
    dockerBin = "${pkgs.${docker}}/bin/${docker}";
  in ''
    NETNAME=default
    SUBNET="172.20.0.0/23"
    if ! ${dockerBin} network inspect "$NETNAME" >/dev/null 2>&1; then
      ${dockerBin} network create "$NETNAME" --driver bridge --ipam-driver "$NETNAME" --subnet "$SUBNET"
    fi
  '';

  # Set up docker containers
  virtualisation.oci-containers.containers = {

    # External dependencies
    redis = {
      image = "redis:alpine";
      volumes = [ "/mailu/redis:/data" ];
      dependsOn = [ "resolver" ];
      extraOptions = [
        "--dns=172.20.1.1"
      ];
    };

    # Core services
    front = {
      image = "mailu/nginx:1.9";
      environmentFiles = [ /data/mailu.env ];
      ports = [
        "80:80"
        "443:443"
        "25:25"
        "465:465"
        "587:587"
        "110:110"
        "995:995"
        "143:143"
        "993:993"
      ];
      volumes = [
        "/mailu/certs:/certs"
        "/mailu/overrides/nginx:/overrides:ro"
      ];
      dependsOn = [ "resolver" ];
      extraOptions = [
        "--log-driver=json-file"
        "--dns=172.20.1.1"
      ];
    };

    resolver = {
      image = "mailu/unbound:1.9";
      environmentFiles = [ /data/mailu.env ];
      extraOptions = [
        "--net=default"
        "--ip=172.20.1.1"
      ];
    };

    admin = {
      image = "mailu/admin:1.9";
      environmentFiles = [ /data/mailu.env ];
      volumes = [
        "/mailu/data:/data"
        "/mailu/dkim:/dkim"
      ];
      dependsOn = [ "redis" "resolver" ];
      extraOptions = [
        "--dns=172.20.1.1"
      ];
    };

    imap = {
      image = "mailu/dovecot:1.9";
      environmentFiles = [ /data/mailu.env ];
      volumes = [
        "/mailu/mail:/mail"
        "/mailu/overrides/dovecot:/overrides:ro"
      ];
      dependsOn = [ "front" "resolver" ];
      extraOptions = [
        "--dns=172.20.1.1"
      ];
    };

    smtp = {
      image = "mailu/postfix:1.9";
      environmentFiles = [ /data/mailu.env ];
      volumes = [
        "/mailu/mailqueue:/queue"
        "/mailu/overrides/postfix:/overrides:ro"
      ];
      dependsOn = [ "front" "resolver" ];
      extraOptions = [
        "--dns=172.20.1.1"
      ];
    };

    antispam = {
      image = "mailu/rspamd:1.9";
      environmentFiles = [ /data/mailu.env ];
      volumes = [
        "/mailu/filter:/var/lib/rspamd"
        "/mailu/overrides/rspamd:/etc/rspamd/override.d:ro"
      ];
      dependsOn = [ "front" "resolver" ];
      extraOptions = [
        "--hostname=antispam"
        "--dns=172.20.1.1"
      ];
    };

    webdav = {
      image = "mailu/radicale:1.9";
      environmentFiles = [ /data/mailu.env ];
      volumes = [ "/mailu/dav:/data" ];
      dependsOn = [ "resolver" ];
      extraOptions = [
        "--dns=172.20.1.1"
      ];
    };

    fetchmail = {
      image = "mailu/fetchmail:1.9";
      environmentFiles = [ /data/mailu.env ];
      volumes = [ "/mailu/data/fetchmail:/data" ];
      dependsOn = [ "resolver" ];
      extraOptions = [
        "--dns=172.20.1.1"
      ];
    };

    # Webmail
    webmail = {
      image = "mailu/roundcube:1.9";
      environmentFiles = [ /data/mailu.env ];
      volumes = [
        "/mailu/webmail:/data"
        "/mailu/overrides/roundcube:/overrides:ro"
      ];
      dependsOn = [ "imap" "resolver" ];
      extraOptions = [
        "--dns=172.20.1.1"
      ];
    };

  };

  swapDevices = [ { device = "/swapfile"; } ];

  system.stateVersion = "22.05";

}
