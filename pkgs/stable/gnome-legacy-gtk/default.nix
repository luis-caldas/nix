{
  lib,
  stdenv,
  buildPackages,
  fetchFromGitHub,
  nixosTests,
}:
let

  # Name
  givenName = "mine";

  # Source
  src = fetchFromGitHub {
    owner = "luis-caldas";
    repo = "gnome-gtk-switcher";
    rev = "47bc7fc8aa54208750c0e1d68357a0e33183af15";
    sha256 = "sha256-TP6Hn2n0zjI6HD6WNj9fPpjB+RdH8y2Vy/DVBHPM6QM=";
  };

  # UUID
  uuid = let
    data = builtins.fromJSON (builtins.readFile "${src}/metadata.json");
  in
    data.uuid;

in stdenv.mkDerivation rec {

  # Versioning
  pname = "gnome-shell-extension-${givenName}";
  version = "0.0.1";

  # Source
  inherit src;

  # Build
  nativeBuildInputs = [ buildPackages.glib ];
  buildPhase = ''
    runHook preBuild
    if [ -d schemas ]; then
      glib-compile-schemas --strict schemas
    fi
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/gnome-shell/extensions/
    cp -r -T . $out/share/gnome-shell/extensions/${uuid}
    runHook postInstall
  '';

  # Passthrough
  passthru = {
    extensionPortalSlug = givenName;
    # UUID
    extensionUuid = uuid;
    # Tests
    tests.gnome-extensions = nixosTests.gnome-extensions;
  };

}
