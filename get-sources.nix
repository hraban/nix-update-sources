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
