{ buildFirefoxXpiAddon, fetchurl, stdenv }:
{
  "no-script" = buildFirefoxXpiAddon {
    pname = "no-script";
    version = "11.1.4";
    addonId = "{73a6fe31-595d-460b-a920-fcc0f8843232}";
    url = "https://addons.mozilla.org/firefox/downloads/file/3667094";
    sha256 = "133x3ygxjpkv9mfw64yp4ax5gzqwp8lhqqqy45wnd07sxivqnwr9";
    meta = with stdenv.lib; {
      platforms = platforms.all;
    };
  };
  "google-translate" = buildFirefoxXpiAddon {
    pname = "google-translate";
    version = "4.0.6";
    addonId = "jid1-93WyvpgvxzGATw@jetpack";
    url = "https://addons.mozilla.org/firefox/downloads/file/3453038";
    sha256 = "1l41nnlazj1ynlvx6j61gwsjhpfav9a37ydswmsdpfxj3fchgppx";
    meta = with stdenv.lib; {
      platforms = platforms.all;
    };
  };
  "tampermonkey" = buildFirefoxXpiAddon {
    pname = "tampermonkey";
    version = "4.11.6117";
    addonId = "firefox@tampermonkey.net";
    url = "https://addons.mozilla.org/firefox/downloads/file/3617060";
    sha256 = "0cgj0wkdc9f664kgbnwmwgcfqjs18d0rnf0cr1z1gbx6dxr1z293";
    meta = with stdenv.lib; {
      platforms = platforms.all;
    };
  };
  "h264ify" = buildFirefoxXpiAddon {
    pname = "h264ify";
    version = "1.1.0";
    addonId = "jid1-TSgSxBhncsPBWQ@jetpack";
    url = "https://addons.mozilla.org/firefox/downloads/file/3398929";
    sha256 = "05d5ay633i98w84srcpmzqb47d18hkdxfm6ql40rqdd2n553rgc7";
    meta = with stdenv.lib; {
      platforms = platforms.all;
    };
  };
  "old-youtube" = buildFirefoxXpiAddon {
    pname = "old-youtube";
    version = "11.1.4";
    addonId = "old_youtube@example.com";
    url = "https://addons.mozilla.org/firefox/downloads/file/3665510";
    sha256 = "0m3v3l4dhn53a2xg2pikk9kjmap4149ad80s9wzfvqg81bk66hgl";
    meta = with stdenv.lib; {
      platforms = platforms.all;
    };
  };
  "search-image" = buildFirefoxXpiAddon {
    pname = "search-image";
    version = "3.1.0";
    addonId = "{2e5ff8c8-32fe-46d0-9fc8-6b8986621f3c}";
    url = "https://addons.mozilla.org/firefox/downloads/file/3641782/search_by_image-3.1.0-an+fx.xpi";
    sha256 = "193934y6qbmmlkmdkwqjqv5py3xlc0hap7clpzlynk0ccz10zyv8";
    meta = with stdenv.lib; {
      platforms = platforms.all;
    };
  };
  "dark-theme" = buildFirefoxXpiAddon {
    pname = "dark-theme";
    version = "1.0.2.0";
    addonId = "{1afaee19-8dde-4b0e-8c84-f46ca0f02f06}";
    url = "https://addons.mozilla.org/firefox/downloads/file/1697943/dark_theme_for_firefox-1.0.2.0-an+fx.xpi";
    sha256 = "0qfm4pwy9cwa1scir703d4ap3gfxndaahrqhysb69glp1zyjffzn";
    meta = with stdenv.lib; {
      platforms = platforms.all;
    };
  };
}
