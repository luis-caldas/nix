{ buildEnv
, makeWrapper
, srb2kart-unwrapped
, srb2kart-data
, srb2kart-link
}:

buildEnv {

  name = "${srb2kart-unwrapped.pname}-wrapped";
  inherit (srb2kart-unwrapped) meta;

  buildInputs = [ makeWrapper ];

  paths = [ srb2kart-unwrapped srb2kart-data srb2kart-link ];

  pathsToLink = [ "/" "/bin" "/share" ];

  postBuild = ''
    for i in $out/bin/*; do
      wrapProgram "$i" \
        --set SRB2WADDIR "$out/share/srb2kart"
    done
  '';

}
