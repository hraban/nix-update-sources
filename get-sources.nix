# Copyright © 2022  Hraban Luyat
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
  pkgs ? import <nixpkgs> {}
, scope
}:

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
generateSources scope
