{ lib
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
  version = "0.12";

  src = builtins.fetchGit {
    url = "https://github.com/uunicorn/${pname}";
    ref = version;
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
