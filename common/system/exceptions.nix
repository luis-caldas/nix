{ lib, pkgs, mpkgs, my, ... }:
{

  # Allow unfree stuff
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "brgenml1lpr"
    "intel-ocl"
    "memtest86-efi"
  ];

  # Allow some insecure packages
  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.0.2u"
  ];

  # Overrides
  nixpkgs.config.packageOverrides = pkgs: {
    # Add custom image to OVMF UEFI
    OVMFFull = pkgs.OVMFFull.overrideAttrs (attrs: {
        pname = attrs.pname + "-custom-logo";
        postPatch = (if (builtins.hasAttr "postPatch" attrs) then attrs.postPatch else "") + ''
          "${pkgs.ffmpeg}/bin/ffmpeg" -i "${my.projects.wallpapers}/papes/dpm-navy-small.png" -pix_fmt rgb24 -y -vf scale=256:-1 "./MdeModulePkg/Logo/Logo.bmp"
        '';
    });
    fprintd = mpkgs.fprintd-clients;
    # Fix Intel OCL URL
    intel-ocl = pkgs.intel-ocl.overrideAttrs (oldAttrs: {
      src = pkgs.fetchzip {
        url = "http://registrationcenter-download.intel.com/akdlm/irc_nas/11396/SRB5.0_linux64.zip";
        sha256 = "0qbp63l74s0i80ysh9ya8x7r79xkddbbz4378nms9i7a0kprg9p2";
        stripRoot = false;
      };
    });
  };

}