{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };
  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system}.pkgs;
    in
    {
      packages.${system}.default = pkgs.callPackage ./default.nix { };
      nixosModules.default = import ./spockServerSystemd.nix;
      formatter.${system} = pkgs.nixpkgs-fmt;
    };
}
