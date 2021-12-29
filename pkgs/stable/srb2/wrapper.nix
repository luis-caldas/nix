{ buildEnv, makeWrapper, srb2-unwrapped, srb2-data, srb2-link }:

assert srb2-unwrapped.version == srb2-data.version;

buildEnv {

  name = "srb2-${srb2-unwrapped.version}";
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
