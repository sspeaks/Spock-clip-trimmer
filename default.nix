{pkgs,...}:
let 
  Spock-core = pkgs.haskell.lib.doJailbreak (pkgs.haskellPackages.Spock-core);
  hPacks = pkgs.haskellPackages.override {
    overrides = _: _: {
      inherit Spock-core;
    };
  };
in
hPacks.callCabal2nix "spock" ./. {}
