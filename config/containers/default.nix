{ pkgs, lib, config, ... }:
let

  # A base image for all the custom images that will be built on top of it
  baseImage = pkgs.dockerTools.buildImage {

    # Names
    name = "local/base";
    tag = "latest";

    # Packages needed for the image
    copyToRoot = with pkgs; [
      tini
      bash bashInteractive
      tree
      busybox coreutils
      curl wget
      gnugrep findutils moreutils util-linux
      cron openssl cacert
    ];

    # Script to run at the start as root
    runAsRoot = ''
      #!${pkgs.bash}/bin/bash
      mkdir -p /tmp
      ln -s /etc/ssl/certs/ca-bundle.crt /etc/ssl/certs/ca-certificates.crt
    '';

    # Environment variables for the image
    config.Env = [
      "TZ=${config.mine.system.timezone}"
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    ];

  };

  # Path to all the images
  imagesPath = ./images;

  # Create a list with all the image files for each container
  allImages = builtins.attrNames (
    lib.attrsets.filterAttrs (name: value: value == "regular") (builtins.readDir imagesPath)
  );

in {

  imports = [

    # Import all the relative functions
    ./functions.nix

  ];

  # The functions to the overlay
  nixpkgs.overlays = [

    # The overlay
    (final: prev: {

      # All the images
      container.images = builtins.listToAttrs (map (eachFile: {
        name = lib.strings.removeSuffix ".nix" eachFile;
        value = import (imagesPath + ("/" + eachFile)) { inherit baseImage pkgs; };
      }) allImages);

    })

  ];

}
