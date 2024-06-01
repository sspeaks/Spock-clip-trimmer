{ pkgs, ... }:
let
  spockSource = pkgs.fetchFromGitHub {
    owner = "agrafix";
    repo = "Spock";
    rev = "40d028bfea0e94ca7096c719cd024ca47a46e559";
    hash = "sha256-HIsVmGa9eOBjIc70asMuYbarv8C5ipxucAKUGltpbpc=";
  };
  Spock-core = pkgs.haskellPackages.callCabal2nixWithOptions "Spock" spockSource "--subpath Spock-core" { };
  hPacks = pkgs.haskellPackages.override {
    overrides = _: _: {
      inherit Spock-core;
    };
  };
in
hPacks.callCabal2nix "spock" ./. { }
