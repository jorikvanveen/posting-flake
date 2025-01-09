{
  inputs = {
    nixpkgs.url = "github:jorikvanveen/nixpkgs-posting?ref=135109926a3f11510d6f340ea9c8880385a0438f";
    utils.url = "github:numtide/flake-utils";
    utils.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { nixpkgs, utils, ... }: utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages = rec {
        default = posting;
        posting = pkgs.posting;
      };
    }
  );
}
