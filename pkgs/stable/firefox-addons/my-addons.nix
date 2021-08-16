{ buildFirefoxXpiAddon, fetchurl, stdenv, lib }:
{
  "dark-theme" = buildFirefoxXpiAddon {
    pname = "dark-theme";
    version = "1.0.2.0";
    addonId = "{1afaee19-8dde-4b0e-8c84-f46ca0f02f06}";
    url = "https://addons.mozilla.org/firefox/downloads/file/1697943/dark_theme_for_firefox-1.0.2.0-an+fx.xpi";
    sha256 = "0qfm4pwy9cwa1scir703d4ap3gfxndaahrqhysb69glp1zyjffzn";
    meta = with lib; {
      platforms = platforms.all;
    };
  };
}
