{ lib
, stdenv
, libusb1
, fetchFromGitHub
}:

stdenv.mkDerivation {

  name = "bs";
  version = "v1";

  src = fetchFromGitHub {
    owner = "machdyne";
    repo = "blaustahl";
    rev = "03cb78cdb1be0397230db6bdc2cd2ec68f774077";
    sha256 = "sha256-9HSDVhTDcaj7kAVqTNPhtPeftP3M5gVlTLZIzN1soqg=";
  };

  sourceRoot = "./source/sw";

  makeFlags = [
    "CFLAGS=-I${libusb1.dev}/include"
    "LDFLAGS=-L${libusb1.out}/lib"
    "bindir=/bin/bs"
    "DESTDIR=$(out)"
  ];

}