{ mkDerivation, base, directory, easy-file, filepath, lib, mtl
, process, Spock, text, unordered-containers, ffmpeg, makeWrapper, time, http-types
}:
mkDerivation {
  pname = "spock";
  version = "0.1.0.0";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  buildDepends = [ ffmpeg makeWrapper ];
  executableHaskellDepends = [
    base directory easy-file filepath mtl process Spock text
    unordered-containers time http-types
  ];
  license = "unknown";
  hydraPlatforms = lib.platforms.none;
  postFixup = ''
        wrapProgram $out/bin/spock --prefix PATH : ${lib.makeBinPath [ffmpeg]}
      '';
}
