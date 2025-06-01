{pkgs,...}:
let 
  Spock-core = pkgs.haskell.lib.doJailbreak (pkgs.haskellPackages.Spock-core);
  serverSource = builtins.path { path = ./.; name = "source"; };
  hPacks = pkgs.haskellPackages.override {
    overrides = _: _: {
      inherit Spock-core;
    };
  };
in
hPacks.callCabal2nix "spock" serverSource {}
