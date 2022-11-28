{
  description = "Scan a scope for sources which can be updated";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    gitignore = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:hercules-ci/gitignore.nix";
    };
    hly-nixpkgs.url = "github:hraban/nixpkgs/feat/lisp-packages-lite";
    # This isn’t necessary anymore now that lispPackagesLite ships with latest
    # ASDFv3, but I’m leaving it in as a demonstration.
    asdf-src = {
      url = "git+https://gitlab.common-lisp.net/asdf/asdf";
      flake = false;
    };
  };
  outputs = {
    self, nixpkgs, asdf-src, hly-nixpkgs, gitignore, flake-utils
  }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        cleanSource = src: gitignore.lib.gitignoreSource (pkgs.lib.cleanSource src);
        inherit (pkgs.callPackage hly-nixpkgs {}) lispPackagesLite;
      in
      with lispPackagesLite;
      let
        # How to create a new lisp dependency on the fly from source
        asdf = lispDerivation { src = asdf-src; lispSystem = "asdf"; };
      in
        {
          packages = {

            default = pkgs.writeShellScriptBin "my-test" ''
              nix run .#parse -- $(nix build --no-link --print-out-paths .#sources)
            '';

            # Program that ingests a sources.json and suggests updates
            parse = lispDerivation {
              lispSystem = "update-sources";
              lispDependencies = [ arrow-macros inferior-shell asdf str ];
              src = cleanSource ./.;
              installPhase = ''
                mkdir -p "$out/bin"
                cp dist/update-sources "$out/bin/"
              '';
            };

            # Create a JSON file with every git source derivation in this entire
            # scope. This happens to be easiest to do in Nix.
            sources = pkgs.callPackage ./get-sources.nix { scope = lispPackagesLite; };
          };
        });
  }
