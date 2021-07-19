{ lib
, buildPythonPackage
, dbus-python
, pygobject3
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

  propagatedBuildInputs = nativeBuildInputs;

  postInstall = ''
    wrapProgram $out/lib/open-fprintd/open-fprintd --set PYTHONPATH $PYTHONPATH
  '';

  meta = with lib; {
    description = "Open Fprintd package for third party interfaces";
  };

}
