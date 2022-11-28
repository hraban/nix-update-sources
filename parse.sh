#!/usr/bin/env bash

set -euo pipefail

# Ironically, the best way to compare version strings in bash is... Nix!
function versionOlder {
    out=$(nix-instantiate --read-write-mode --strict --eval -E "(
      import ../../../.. {}
    ).lib.strings.versionOlder \"$1\" \"$2\"")
	[[ "$out" == "true" ]]
}

jq -r 'to_entries | .[]  | "\(.key) \(.value.rev) \(.value.gitRepoUrl)" '  |
    while read system old url ; do
        < <(git ls-remote $url HEAD)  read head _
        if [[ "$head" != "$old" ]] ; then
            echo "$system: $old -> $head"
        fi
    done
