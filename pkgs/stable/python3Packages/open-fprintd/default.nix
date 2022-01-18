{ lib
, fetchFromGitHub
, buildPythonPackage
, dbus-python
, pygobject3
}:

buildPythonPackage rec {

  pname = "open-fprintd";
  version = "0.6";

  src = fetchFromGitHub {
    owner = "uunicorn";
    repo = pname;
    rev = "6250c540aa325620f1838d27d7a920347d17f8d0";
    sha256 = "0d8grn2ywiajxk5iifb3w8xgk6zz95wvga4alrggyir6vg16wldr";
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
