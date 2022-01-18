{ lib
, fetchFromGitHub
, buildPythonPackage
, cryptography
, dbus-python
, pygobject3
, pyyaml
, pyusb
, innoextract
}:

buildPythonPackage rec {

  pname = "python-validity";
  version = "0.13";

  src = fetchFromGitHub {
    owner = "uunicorn";
    repo = pname;
    rev = "c94c243bce6a1f8451cbb2b39299f21d3832bf5f";
    sha256 = "044lh1p1fwg0mq5kaz1ipdwaf89svzni6f41plxi304vaxv3z5j8";
  };

  nativeBuildInputs = [
    cryptography
    innoextract
    dbus-python
    pygobject3
    pyyaml
    pyusb
  ];

  propagatedBuildInputs = nativeBuildInputs;

  preBuild = ''
    sed -e 's|/usr/share/python-validity/|/tmp/|g' -i bin/validity-sensors-firmware
    sed -e 's|/usr/share/python-validity/|/var/lib/python-validity/|g' -i dbus_service/dbus-service
    sed -e 's|/usr/share/python-validity/|/var/lib/python-validity/|g' -i validitysensor/sensor.py
    sed -e 's|/usr/share/python-validity|/var/lib/python-validity|g' -i validitysensor/upload_fwext.py
  '';

  postInstall = ''
    wrapProgram $out/bin/validity-sensors-firmware --set PYTHONPATH $PYTHONPATH
    wrapProgram $out/bin/validity-led-dance --set PYTHONPATH $PYTHONPATH
    wrapProgram $out/lib/python-validity/dbus-service --set PYTHONPATH $PYTHONPATH
  '';

  meta = with lib; {
    description = "Thinkpad fingerprint driver";
  };

}
