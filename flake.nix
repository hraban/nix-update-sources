{
  description = "Scan a scope for sources which can be updated";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    gitignore = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:hercules-ci/gitignore.nix";
    };
    hly-nixpkgs.url = "github:hraban/nixpkgs/feat/lisp-packages-lite";
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
        asdf = lispDerivation { src = asdf-src; lispSystem = "asdf"; };
      in
        {
          packages = {

            # Create a JSON file with every git source derivation in this entire
            # scope
            sources =
              with pkgs.lib;
              with rec {
                a = attrsets;
                b = builtins;
                l = lists;
                s = strings;
                t = trivial;
                gitUrl = drv:
                  if drv ? gitRepoUrl
                  then {
                    inherit (drv) gitRepoUrl rev;
                  }
                  else if drv ? src
                  then gitUrl drv.src
                  else null;
                extractDerivs = filterAttrs (n: a.isDerivation);
                extractSrc = mapAttrs (n: gitUrl);
                notNull = x: x != null;
                generateSources = (flip pipe) [
                  extractDerivs
                  extractSrc
                  (filterAttrs (n: notNull))
                  b.toJSON
                  (pkgs.writeText "sources.json")
                ];
              };
              generateSources lispPackagesLite;

            # Program that ingests a sources.json and suggests updates
            default = lispDerivation {
              lispSystem = "update-sources";
              lispDependencies = [ inferior-shell asdf ];
              src = cleanSource ./.;
              # Binary is automatically built using ASDF’s :build-operation
              # "program-op"
              installPhase = ''
                mkdir -p "$out/bin"
                cp dist/update-sources "$out/bin/"
              '';
            };
          };
        });
  }
