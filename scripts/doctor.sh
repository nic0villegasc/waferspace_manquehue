#!/bin/bash
# make doctor: check what this repository needs on this machine, and say how to fix what is missing.
# Changes nothing. Exit code 1 when something needed is missing.
cd "$(dirname "$0")/.." || exit 1
bad=0
ok()   { printf "  ok    %s\n" "$1"; }
miss() { printf "  MISS  %s\n        fix: %s\n" "$1" "$2"; bad=1; }
note() { printf "  note  %s\n" "$1"; }

echo "Tools"
for t in git python3 make; do
    command -v $t >/dev/null && ok "$t" || miss "$t" "install $t"
done
if [ -f /opt/librelane-templates/activate/gf.sh ]; then
    ok "flow tools: AC3E IC Toolbox (/opt/librelane-templates/activate/gf.sh)"
elif command -v nix-shell >/dev/null; then
    ok "flow tools: nix-shell (the first make chip downloads the template's tools, several GB)"
else
    miss "flow tools (LibreLane, KLayout, OpenROAD)" "work in the AC3E IC Toolbox, or install Nix: https://nixos.org/download"
fi
if command -v gh >/dev/null; then
    if gh auth status >/dev/null 2>&1; then ok "gh logged in"; else miss "gh not logged in" "gh auth login --web"; fi
else
    miss "gh (GitHub CLI, to fetch and publish macros)" "install it: https://cli.github.com"
fi

echo "Macro sources (sources.yaml)"
for repo in $(grep -E "^\s+repo:" sources.yaml | awk '{print $2}' | sort -u); do
    if gh api "repos/$repo" --silent >/dev/null 2>&1; then ok "read access to $repo"
    else miss "no read access to $repo" "ask its owner for read access, then gh auth login again"; fi
done
grep -q "^  manual:" sources.yaml && note "an entry is still by hand (manual:), see sources.yaml"

echo "Macros (macros/)"
if python3 scripts/fetch.py --check | sed "s/^/  /"; then ok "every macro matches sources.yaml"
else miss "macros missing or changed" "make fetch"; fi

echo "Optional"
[ -d "${CROC:-$HOME/Documents/manquehue_chip}/scripts/sim" ] && ok "manquehue_chip checkout (make gls)" \
    || note "no manquehue_chip checkout: make gls is skipped (CROC=<checkout> to point at one)"
[ -d .tools/gf180mcu-precheck ] && ok "wafer.space precheck in .tools/" \
    || note "the first make precheck clones the wafer.space precheck and its PDK into .tools/"

[ $bad = 0 ] && echo "Ready: make chip" || echo "Fix the MISS lines above, then make doctor again."
exit $bad
