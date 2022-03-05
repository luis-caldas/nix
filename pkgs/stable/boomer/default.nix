{ stdenv
, lib
, callPackage
, fetchFromGitHub
, nim
, xorg
, libGL
}:
let

  pname = "boomer";
  owner = "tsoding";
  repo  = pname;
  version = "0.0.1";

  ogSrc = fetchFromGitHub {
    inherit owner repo;
    rev = "cc0f5311193da8361ee782a421d6bc4ad8541cf3";
    sha256 = "0pv88w4my7gbi4hcpdijdvjcscwflgq46i3mszq1mla4wag38a6z";
  };

  x11-nim = fetchFromGitHub {
    owner = "nim-lang";
    repo = "x11";
    rev = "2093a4c01360cbb5dd33ab79fd4056e148b53ca1";
    sha256 = "0h770z36g2pk49pm5l1hmk9bi7a58w8csd7wqxcwy0bi41g74x6r";
  };

  opengl-nim = fetchFromGitHub {
    owner = "nim-lang";
    repo = "opengl";
    rev = "2ca5a0995dc6c5e1051e48a857a52fc473bd850c";
    sha256 = "1lw2mc95g8b4175pp24aw7qx5qnl4srzw99adn9il7pf6569kqz6";
  };

  nimPackage = callPackage "${ogSrc}/overlay/nim_1_0.nix" {};

in stdenv.mkDerivation rec {

  inherit pname owner repo version;
  src = ogSrc;

  buildInputs = [ nimPackage xorg.libX11 xorg.libXrandr libGL ];

  buildPhase = ''
    HOME="''${TMPDIR}"
    nim -p:${x11-nim}/ -p:${opengl-nim}/src c -d:release src/boomer.nim
  '';

  installPhase = "install -Dt $out/bin src/boomer";

  fixupPhase = "patchelf --set-rpath ${lib.makeLibraryPath [stdenv.cc.cc xorg.libX11 xorg.libXrandr libGL]} $out/bin/boomer";

  meta = with lib; {
    description = "Zoomer application for Linux";
    homepage = "https://github.com/tsoding/boomer";
    license = licenses.mit;
  };

}
