{ lib
, buildPythonPackage
, dbus-python
}:

buildPythonPackage rec {

  pname = "open-fprintd";
  version = "0.6";

  src = builtins.fetchGit {
    url = "https://github.com/uunicorn/${pname}";
    ref = version;
  };

  nativeBuildInputs = [
    dbus-python
  ];

  propagatedBuildInputs = [
    dbus-python
  ];

  installPhase = ''
    cp $out/lib/open-fprintd/open-fprintd $out/bin/open-fprintd
  '';

  meta = with lib; {
    description = "Open Fprintd package for third party interfaces";
  };

}
