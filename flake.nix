{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      sources = builtins.fromJSON (builtins.readFile ./nix/sources.json);
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      mk = s: pkgs.callPackage ./nix/package.nix { inherit (s) version url hash; };
    in {
      packages.x86_64-linux = {
        default = mk sources.stable;
        stable  = mk sources.stable;
        t3code  = mk sources.stable;
      };
    };
}
