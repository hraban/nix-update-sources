# Copyright © 2022, 2023  Hraban Luyat
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published
# by the Free Software Foundation, version 3 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

{
  description = "Scan a scope for sources which can be updated";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    gitignore = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:hercules-ci/gitignore.nix";
    };
    hly-nixpkgs.url = "github:hraban/nixpkgs/feat/lisp-packages-lite";
  };
  outputs = {
    self, nixpkgs, hly-nixpkgs, gitignore, flake-utils
  }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        cleanSource = src: gitignore.lib.gitignoreSource (pkgs.lib.cleanSource src);
        inherit (pkgs.callPackage hly-nixpkgs {}) lispPackagesLite;
      in
      with lispPackagesLite;
        {
          packages = {
            # Program that ingests a sources.json and suggests updates
            update-sources = lispDerivation {
              name = "update-sources";
              lispSystem = "update-sources";
              lispDependencies = [
                arrow-macros
                asdf
                cl-ppcre
                inferior-shell
                str
              ];
              src = cleanSource ./.;
              installPhase = ''
                mkdir -p "$out/bin"
                cp dist/update-sources "$out/bin/"
              '';
              nativeBuildInputs = [ pkgs.makeWrapper ];
              postInstall = ''
                wrapProgram $out/dist/update-sources --suffix PATH : "${pkgs.jq}/bin"
              '';
              meta = {
                license = pkgs.lib.licenses.agpl3Only;
              };
            };

            default = self.packages.${system}.update-sources;

            # Create a JSON file with every git source derivation in this entire
            # scope. This happens to be easiest to do in Nix.
            sources = pkgs.callPackage ./get-sources.nix { scope = lispPackagesLite; };
          };
          # Utility script to combine both
          apps.default = flake-utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "update" ''
              set -e
              nix build --no-link .#sources
              nix run .#update-sources -- $(nix build --no-link --print-out-paths .#sources)
            '';
          };
        });
  }
