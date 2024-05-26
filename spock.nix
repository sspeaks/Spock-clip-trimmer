{ mkDerivation, base, directory, easy-file, filepath, http-types
, lib, mtl, process, Spock, text, time, unordered-containers, ffmpeg, makeWrapper
}:
mkDerivation {
  pname = "spock";
  version = "0.1.0.0";
  src = ./.;
  isLibrary = false;
  buildDepends = [ ffmpeg makeWrapper ];
  isExecutable = true;
  executableHaskellDepends = [
    base directory easy-file filepath http-types mtl process Spock text
    time unordered-containers
  ];
 postFixup = ''
    wrapProgram $out/bin/spock --prefix PATH : ${lib.makeBinPath [ffmpeg]}
  '';
 license = "unknown";
  mainProgram = "spock";
}
