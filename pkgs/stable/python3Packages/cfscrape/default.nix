{ lib
, buildPythonPackage
, fetchPypi
, file
, stdenv
, requests
}:

buildPythonPackage rec {

  pname = "cfscrape";
  version = "2.1.1";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1vz2i7hljb5qw2g6fmq3dk71drr62l2l43fdwxyyxmp0ai2zjpkw";
  };

  buildInputs = [ requests ];
  propagatedBuildInputs = [ requests ];

  # No tests in archive
  doCheck = false;

  meta = with lib; {
    description = "cfscrape";
  };

}
