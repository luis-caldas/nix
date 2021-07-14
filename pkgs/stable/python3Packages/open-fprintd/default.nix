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
    pygobject3
    dbus-python
  ];

  propagatedBuildInputs = [
    pygobject3
    dbus-python
  ];

  meta = with lib; {
    description = "Open Fprintd package for third party interfaces";
  };

}
