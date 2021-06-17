{ lib
, buildPythonPackage
, fetchPypi
, file
, stdenv
, pysmartdl
, beautifulsoup4
, requests
, click
, fuzzywuzzy
, coloredlogs
, cfscrape
, requests-cache
, tabulate
, pycryptodome
}:

buildPythonPackage rec {

  pname = "anime-downloader";
  version = "5.0.9";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1m7a2qcc3gwmsl5s29c6slwrjz9mdi1hzz5jjdcz6c4aa3cxxsj0";
  };

  buildInputs = [
    pysmartdl
    beautifulsoup4
    requests
    click
    fuzzywuzzy
    coloredlogs
    cfscrape
    requests-cache
    tabulate
    pycryptodome
  ];

  propagateBuildInputs = [
    pysmartdl
    beautifulsoup4
    requests
    click
    fuzzywuzzy
    coloredlogs
    cfscrape
    requests-cache
    tabulate
    pycryptodome
  ];

  # No tests in archive
  doCheck = false;

  meta = with lib; {
    description = "Anime downloader";
    homepage = "https://github.com/vn-ki/anime-downloader";
  };

}
