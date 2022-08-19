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

  # Create network service for docker
  systemd.services."docker-network-mail" = let
    name = "mail";
    subnet = "172.20.0.0/23";
    beforeList = [ "resolver" ];
    beforeAll = map (input: "docker-${input}.service") beforeList;
  in rec {
    wantedBy = [ "multi-user.target" ];
    after = [ "docker.service" "docker.socket" ];
    before = beforeAll;
    requires = after;
    serviceConfig = {
      ExecStart = pkgs.writeScript "docker-network-create-${name}" ''
        #!${pkgs.runtimeShell} -e
        set -x
        if [[ -z "$(${pkgs.docker}/bin/docker network ls | grep "${name}" | tr -d '\n')" ]]; then
          ${pkgs.docker}/bin/docker network create "${name}" --driver bridge --ipam-driver default --subnet "${subnet}"
        fi
      '';
      ExecStop = ''
        ${pkgs.docker}/bin/docker network rm "${name}"
      '';
      RemainAfterExit="true";
      Type="oneshot";
    };
  };

  # Set up docker containers
  virtualisation.oci-containers.containers = {

    # External dependencies
    redis = {
      image = "redis:alpine";
      volumes = [ "/mailu/redis:/data" ];
      dependsOn = [ "resolver" ];
      extraOptions = [
        "--network=mail"
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
        "--network=mail"
        "--log-driver=json-file"
        "--dns=172.20.1.1"
      ];
    };

    resolver = {
      image = "mailu/unbound:1.9";
      environmentFiles = [ /data/mailu.env ];
      extraOptions = [
        "--network=mail"
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
        "--network=mail"
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
        "--network=mail"
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
        "--network=mail"
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
        "--network=mail"
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
        "--network=mail"
        "--dns=172.20.1.1"
      ];
    };

    fetchmail = {
      image = "mailu/fetchmail:1.9";
      environmentFiles = [ /data/mailu.env ];
      volumes = [ "/mailu/data/fetchmail:/data" ];
      dependsOn = [ "resolver" ];
      extraOptions = [
        "--network=mail"
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
        "--network=mail"
        "--dns=172.20.1.1"
      ];
    };

  };

  swapDevices = [ { device = "/swapfile"; } ];

  system.stateVersion = "22.05";

}
