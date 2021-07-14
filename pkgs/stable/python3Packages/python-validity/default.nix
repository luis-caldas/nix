{ lib
, buildPythonPackage
, dbus-python
}:

buildPythonPackage rec {

  pname = "python-validity";
  version = "0.12";

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
