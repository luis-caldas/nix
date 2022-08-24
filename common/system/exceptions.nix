{ lib, pkgs, mpkgs, my, config, ... }:
{

  # Generate config for all packages
  options.exceptions = with lib; {
    unfree = mkOption {
      type = types.listOf types.string;
      default = [];
    };
    overrides = mkOption {
      type = types.functionTo types.attrs;
      default = n: {};
    };
  };

  # General config
  config = {

    # Allow unfree stuff
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) (
      config.exceptions.unfree
    ++ [
      "brgenml1lpr"
      "intel-ocl"
      "memtest86-efi"
    ]);

    # Allow some insecure packages
    nixpkgs.config.permittedInsecurePackages = [
      "openssl-1.0.2u"
    ];

    # Overrides
    nixpkgs.config.packageOverrides = ogpkgs: (
      (config.exceptions.overrides ogpkgs)
      // {
        netdata = ogpkgs.netdata.overrideAttrs (oldAttrs: {
          nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ ogpkgs.makeWrapper ];
          configureFlags = oldAttrs.configureFlags ++ [ "--disable-cloud" ];
          postFixup = oldAttrs.postFixup + ''
            wrapProgram $out/libexec/netdata/plugins.d/charts.d.plugin \
              --set PATH ${lib.makeBinPath [
                ogpkgs.nut
                ogpkgs.bash
              ]}
          '';
        });
      }
    );

  };

}
