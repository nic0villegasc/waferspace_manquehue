#!/usr/bin/env python3
"""Prepare a gf180mcu standard-cell CDL for LVS against a KLayout GDS extraction.

Always empties the physical-only `antenna` cell: its diode lines break
KLayout's generic SPICE-D-element parser, and the cell carries no signal
pins relevant to LVS anyway.

Well-pin folding is opt-in per pin via --tie, and defaults to folding
NEITHER VNW nor VPW. Fold only the pins whose rail your LVS deck's own
connectivity setup ALSO merges at the *layout* extraction stage (e.g. a
connect_global on the substrate layer), matching how KLayout's hierarchical
LVS extracts each standard cell as its own leaf circuit: a well/substrate
tap only becomes part of VDD/VSS within that leaf if the deck globally ties
it (a true single chip-wide net, e.g. p-substrate); an n-well tap that's
only merged via physical abutment between adjacent cells stays a genuine,
separate leaf-level pin, and folding it anyway gives every leaf-cell
comparison a spurious pin-count mismatch that has nothing to do with a real
LVS violation. verilog2spice.py's own default `--tie VNW=VDD --tie VPW=VSS`
handles the un-folded case correctly on the schematic side: it connects
each *instantiation's* VNW/VPW pin to VDD/VSS, mirroring what abutment does
in the layout, without touching the leaf definition's pin count.

--rename-model renames MOSFET model names (e.g. nfet_05v0 -> nmos_5p0), so
the schematic's device classes end up literally same-named as whatever your
LVS deck's own layout-side device extraction registers them as (check the
deck's extract_devices(mos4("..."), ...) calls). With matching names,
KLayout's NetlistComparer treats them as the same class automatically --
no same_device_classes equivalence declaration needed at all. That matters
because a deck's own built-in same_device_classes DSL helper may not always
cooperate (see the note in gf180mcu.lvs), and renaming to match sidesteps
needing it, so the deck's native `compare` (and the .lvsdb you open in
KLayout) becomes correct and trustworthy directly, instead of needing a
separate script's disconnected result.

Usage:
  python3 fold_wells.py in.cdl out.cdl                  # antenna-strip only
  python3 fold_wells.py --tie VPW=VSS in.cdl out.cdl    # also fold VPW->VSS
  python3 fold_wells.py --rename-model nfet_05v0=nmos_5p0 \\
      --rename-model pfet_05v0=pmos_5p0 in.cdl out.cdl
"""
import re
import sys


def logical_lines(fh):
    pending = None
    for raw in fh:
        line = raw.rstrip("\r\n")
        s = line.strip()
        if s.startswith("+") and pending is not None:
            pending += " " + s[1:].strip()
            continue
        if pending is not None:
            yield pending
        pending = line
    if pending is not None:
        yield pending


def dedup(seq):
    seen, out = set(), []
    for x in seq:
        if x not in seen:
            seen.add(x)
            out.append(x)
    return out


def main(inp, outp, fold, rename_model):
    fold_tok = re.compile(r"\b(%s)\b" % "|".join(fold)) if fold else None
    rename_tok = (re.compile(r"\b(%s)\b" % "|".join(re.escape(k) for k in rename_model),
                              re.IGNORECASE)
                  if rename_model else None)
    # case-insensitive lookup for the replacement (CDL model names may
    # appear in any case; keep the requested-case target verbatim)
    rename_lower = {k.lower(): v for k, v in rename_model.items()}

    def apply_line_subs(line):
        if fold_tok:
            line = fold_tok.sub(lambda m: fold[m.group(1)], line)
        if rename_tok:
            line = rename_tok.sub(lambda m: rename_lower[m.group(1).lower()], line)
        return line

    out = []
    skip = False
    for line in logical_lines(open(inp, errors="replace")):
        s = line.strip()
        low = s.lower()
        if low.startswith(".subckt"):
            toks = s.split()
            name, pins = toks[1], toks[2:]
            if fold:
                pins = dedup([fold.get(p, p) for p in pins])
            out.append(".SUBCKT %s %s" % (name, " ".join(pins)))
            skip = "antenna" in name.lower()      # empty the antenna body
            continue
        if low.startswith(".ends"):
            out.append(apply_line_subs(line))
            skip = False
            continue
        if skip:
            continue
        if fold and s.upper().startswith("*.PININFO"):
            kept = [t for t in s.split() if t.split(":")[0] not in fold]
            out.append(" ".join(kept))
            continue
        out.append(apply_line_subs(line))
    with open(outp, "w") as fh:
        fh.write("\n".join(out) + "\n")


if __name__ == "__main__":
    args = sys.argv[1:]
    fold = {}
    rename_model = {}
    rest = []
    i = 0
    while i < len(args):
        if args[i] == "--tie":
            i += 1
            pin, _, net = args[i].partition("=")
            if pin not in ("VNW", "VPW") or not net:
                sys.exit("--tie must be VNW=<net> or VPW=<net>, got: %s" % args[i])
            fold[pin] = net
        elif args[i] == "--rename-model":
            i += 1
            frm, _, to = args[i].partition("=")
            if not frm or not to:
                sys.exit("--rename-model must be FROM=TO, got: %s" % args[i])
            rename_model[frm] = to
        else:
            rest.append(args[i])
        i += 1
    if len(rest) != 2:
        sys.exit("usage: fold_wells.py [--tie VNW=<net>] [--tie VPW=<net>] "
                  "[--rename-model FROM=TO ...] in.cdl out.cdl")
    main(rest[0], rest[1], fold, rename_model)
