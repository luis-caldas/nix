{ lib
, buildPythonPackage
, fetchPypi
, file
, stdenv
, sphinx
}:

buildPythonPackage rec {

  pname = "pySmartDL";
  version = "1.3.4";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1x1m1in912zkas7b5bpm8bymy9h86ryv54yaplrlsizkjhb5s9rm";
  };

  buildInputs = [ sphinx ];
  propagatedBuildInputs = [ sphinx ];

  # No tests in archive
  doCheck = false;

  meta = with lib; {
    description = "pysmartdl";
  };

}
