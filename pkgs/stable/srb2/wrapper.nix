{ buildEnv
, makeWrapper
, srb2-unwrapped
, srb2-data
, srb2-link
}:

buildEnv {

  name = "${srb2-unwrapped.pname}-wrapped";
  inherit (srb2-unwrapped) meta;

  buildInputs = [ makeWrapper ];

  paths = [ srb2-unwrapped srb2-data srb2-link ];

  pathsToLink = [ "/" "/bin" "/share" ];

  postBuild = ''
    for i in $out/bin/*; do
      wrapProgram "$i" \
        --set SRB2WADDIR "$out/share/srb2"
    done
  '';

}
