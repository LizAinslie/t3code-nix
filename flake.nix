{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      sources = builtins.fromJSON (builtins.readFile ./nix/sources.json);
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      mk = s: pkgs.callPackage ./nix/package.nix { inherit (s) version url hash; };

      update = pkgs.writeShellApplication {
        name = "update";
        runtimeInputs = with pkgs; [ curl jq yq-go ];
        text = builtins.readFile ./scripts/update.sh;
      };

    in {
      packages.x86_64-linux = {
        default = mk sources.stable;
        stable  = mk sources.stable;
        nightly = mk sources.nightly;
        t3code  = mk sources.stable;
      };

      apps.x86_64-linux.update = {
        type = "app";
        program = "${update}/bin/update";
      };
    };
}
