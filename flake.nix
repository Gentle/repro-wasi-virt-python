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

        craneLib = (crane.mkLib pkgs).overrideToolchain rustTarget;

        witFilter = path: _type: builtins.match ".*wit$" path != null;
        soureFilter = path: type:
          (witFilter path type) || (craneLib.filterCargoSources path type);

        src = pkgs.lib.cleanSourceWith {
          src = ./.;
          filter = soureFilter;
        };

        serverCrate = craneLib.buildPackage {
          inherit src;

          pname = "server";
          version = "0.1.0";

          cargoExtraArgs = "-p server --locked";

          nativeBuildInputs = with pkgs; [
            pkg-config
          ];

          buildInputs = with pkgs; [
            openssl
            # Add additional build inputs here
          ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
            # Additional darwin specific inputs can be set here
            libiconv
          ];
        };

        editorCrate = craneLib.buildPackage {
          inherit src;

          pname = "guest_editor";
          version = "0.1.0";

          cargoExtraArgs = "-p guest_editor --locked --target wasm32-wasi";

          nativeBuildInputs = with pkgs; [
            python311
            pkg-config
            wasilibc
          ];

          buildInputs = with pkgs; [
            openssl
            # Add additional build inputs here
          ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
            # Additional darwin specific inputs can be set here
            libiconv
          ];
                    
        };
      in
      with pkgs;
      {
        formatter = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;

        checks = {
          inherit serverCrate;
        };

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

        packages.default = serverCrate;
        packages.server = serverCrate;
        packages.editor = editorCrate;
      }
    );
}
