{
  description = "Quantim Documents Server";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = { self, nixpkgs, crane, flake-utils, rust-overlay, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
          # for ngrok
          config.allowUnfree = true;
        };

        rustTarget = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain;

      in
      with pkgs;
      {
        formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;

        devShells.default = mkShell {
          buildInputs = [
            openssl
            pkg-config
            wasm-tools
            rustTarget
            wasmtime
            wasm-tools
          ];

          shellHook = ''
          '';
        };
      }
    );
}
