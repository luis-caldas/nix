{ lib
, buildDotnetModule
, fetchFromGitHub
, dotnetCorePackages
}:

buildDotnetModule rec {

  pname = "n-m3u8-re";
  version = "0.2.0-beta";

  src = fetchFromGitHub {
    owner = "nilaoda";
    repo = "N_m3u8DL-RE";
    rev = "v${version}";
    sha256 = "sha256-bjkY+cu/5qCASgGRtpXPQOZQKCFsiobu/OhmI4a4LII=";
  };

  projectFile = "src/N_m3u8DL-RE.sln";

  nugetDeps = ./deps.nix;

  dotnet-sdk = dotnetCorePackages.sdk_8_0;
  dotnet-runtime = dotnetCorePackages.runtime_8_0;

  patches = [ ./publish-fix.patch ];

  meta = with lib; {
    description = "Cross-Platform, modern and powerful stream downloader for MPD/M3U8/ISM";
    homepage = "https://github.com/nilaoda/N_m3u8DL-RE";
    license = licenses.mit;
    platforms = platforms.linux;
  };

}