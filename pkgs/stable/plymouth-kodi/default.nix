{ stdenv
, fetchFromGitHub
}:

rec {

  name = "kodi-animated-logo";

  derivation = stdenv.mkDerivation rec {

    pname = name;
    version = "0.0.1";

    src = pkgs.fetchFromGitHub {
      owner = "solbero";
      repo = "plymouth-theme-${name}";
      rev = "f16d51632ef5d0182821749901af04bbe2efdfd6";
      sha256 = "sha256-e0ps9Fwdcc9iFK8JDRSayamTfAQIbzC+CoN0Yokv7kY=";
    };

    installPhase = ''
      mkdir -p $out/share/plymouth/themes/
      cp -r plymouth-theme-${name}/usr/share/plymouth/themes/${name} $out/share/plymouth/themes/.
      cat plymouth-theme-${name}/usr/share/plymouth/themes/${name}/${name}.plymouth | sed "s@\/usr\/@$out\/@" > $out/share/plymouth/themes/${pname}/${pname}.plymouth
    '';

  }

}