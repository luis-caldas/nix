{ lib
, buildPythonPackage
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
  owner = "anime-dl";
  version = "master";

  src = builtins.fetchGit {
    url = "https://github.com/${owner}/${pname}";
    ref = version;
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

  propagatedBuildInputs = [
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
