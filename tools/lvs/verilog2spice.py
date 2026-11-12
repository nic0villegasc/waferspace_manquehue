#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
verilog2spice.py  (v2 rewrite)

Structured (gate-level) Verilog -> SPICE subckt-instance netlist translator,
tailored for GlobalFoundries gf180mcu netlists written by Synopsys Fusion
Compiler / Design Compiler `write_verilog`.

What it handles that the original script did not:
  * Named connections written with spaces, e.g.  .A1 ( net )   (whitespace-safe)
  * Instances spanning many lines, terminated by ';'
  * Bus PORTS on the top module ( input [15:0] gpio_i ; ) -> bit-expanded
  * Bus CONNECTIONS via Verilog concatenation, e.g. .A ( { a10, a9, ... a2 } )
    mapped MSB-first onto a subckt's per-bit pins (A[8]..A[0] / A<8>.. / A8..)
  * Constants 1'b0 / 1'b1 -> tied to the ground / power rail
  * '+' continuation lines in .SUBCKT headers of the CDL (defensive; the sc CDL
    doesn't use them, but IO/SRAM CDLs might)
  * Per-cell rail discovery from the CDL (pin list + optional *.PININFO), so
    pins that are power/ground/well are auto-tied and never mistaken for signals
  * Implicit well pins (VNW/VPW): connected via a configurable rail map
    (default VNW->VDD, VPW->VSS) so the result is actually simulatable
  * Identifier CASE is preserved (subckt names matched case-insensitively)
  * Long X-lines wrapped with '+' continuations for tool friendliness

Typical usage for the croc_soc / gf180mcu example:

  python3 verilog2spice.py \
      -v top_29_07.v \
      -c libs.ref/gf180mcu_fd_sc_mcu7t5v0/cdl/gf180mcu_fd_sc_mcu7t5v0.cdl \
      -c libs.ref/gf180mcu_fd_ip_sram/cdl/gf180mcu_fd_ip_sram__sram512x8m8wm1.cdl \
      -o croc_soc.sp

Legacy-compatible flags (-spice/-verilog/-output/-pos_pwr/-neg_pwr) are also
accepted so muscle memory from the old script still works.

Distributed under GNU GPLv3 (same as the original).
"""

import argparse
import os
import re
import sys
from datetime import datetime

# ---------------------------------------------------------------------------
# Default set of names treated as power/ground/well rails when a CDL provides
# no *.PININFO. gf180mcu uses VDD/VSS/VNW/VPW; the others are common aliases.
# ---------------------------------------------------------------------------
DEFAULT_RAIL_NAMES = {"VDD", "VSS", "VNW", "VPW", "VPWR", "VGND",
                      "VNB", "VPB", "VDDA", "VSSA", "GND", "VCC"}


# ===========================================================================
#  CDL / SPICE library parsing
# ===========================================================================
class Subckt:
    __slots__ = ("name", "pins", "rails")

    def __init__(self, name, pins, rails):
        self.name = name          # canonical (original-case) name
        self.pins = pins          # ordered list of pin names (original case)
        self.rails = rails        # set of pin names (original case) that are rails


def _logical_lines(fh):
    """Yield logical SPICE lines, folding '+' continuation lines, and keeping
    '*.PININFO' comments (needed) while dropping plain '*' comments."""
    pending = None
    for raw in fh:
        line = raw.rstrip("\r\n")
        stripped = line.strip()
        if stripped.startswith("+"):
            # continuation of previous logical line
            if pending is not None:
                pending += " " + stripped[1:].strip()
            continue
        if pending is not None:
            yield pending
        pending = line
    if pending is not None:
        yield pending


def parse_cdl(paths, rail_names):
    """Parse one or more CDL/SPICE files. Returns dict: lower(name) -> Subckt."""
    subckts = {}
    pininfo_re = re.compile(r"\*\.PININFO\b", re.IGNORECASE)
    for path in paths:
        cur = None                     # (name, pins list)
        cur_pininfo = {}               # pin(lower) -> dir char
        with open(path, "r", errors="replace") as fh:
            for line in _logical_lines(fh):
                s = line.strip()
                low = s.lower()
                if low.startswith(".subckt"):
                    toks = s.split()
                    if len(toks) < 2:
                        continue
                    name = toks[1]
                    pins = toks[2:]
                    cur = (name, pins)
                    cur_pininfo = {}
                elif pininfo_re.search(s) and cur is not None:
                    # *.PININFO A:I B:I VDD:P VSS:G ...
                    body = s.split("PININFO", 1)[1] if "PININFO" in s.upper() else ""
                    # be robust to case of the keyword
                    body = re.split(r"PININFO", s, flags=re.IGNORECASE)[-1]
                    for tok in body.split():
                        if ":" in tok:
                            pn, d = tok.split(":", 1)
                            cur_pininfo[pn.strip().lower()] = d.strip().upper()[:1]
                elif low.startswith(".ends"):
                    if cur is not None:
                        name, pins = cur
                        rails = set()
                        for p in pins:
                            base = _pin_base(p)
                            d = cur_pininfo.get(p.lower())
                            if d in ("P", "G"):           # power / ground per PININFO
                                rails.add(p)
                            elif base.upper() in rail_names:
                                rails.add(p)
                        subckts[name.lower()] = Subckt(name, pins, rails)
                    cur = None
                    cur_pininfo = {}
    return subckts


# ===========================================================================
#  Bus-pin helpers
# ===========================================================================
_BUS_BIT_RE = re.compile(r"^(?P<base>.+?)[\[<](?P<idx>\d+)[\]>]$")


def _pin_base(pin):
    m = _BUS_BIT_RE.match(pin)
    return m.group("base") if m else pin


def format_include(path, mode, relto):
    """Render the path used on a `.INCLUDE` line.
    KLayout resolves a relative .INCLUDE against the directory of the .sp file,
    so 'abs' (the default) is the safe choice when the CDLs live elsewhere."""
    if mode == "none":
        return None
    if mode == "basename":
        return os.path.basename(path)
    if mode == "asis":
        return path
    ap = os.path.abspath(path)
    if mode == "relto" and relto:
        return os.path.relpath(ap, os.path.abspath(relto))
    return ap  # 'abs'


def bus_bits(subckt, base):
    """Return list of (index, pin_name) for a subckt's bus 'base', highest
    index first (MSB-first), or [] if 'base' is not a bus in this subckt."""
    bits = []
    for p in subckt.pins:
        m = _BUS_BIT_RE.match(p)
        if m and m.group("base") == base:
            bits.append((int(m.group("idx")), p))
    bits.sort(key=lambda t: t[0], reverse=True)   # MSB first
    return bits


# ===========================================================================
#  Verilog parsing
# ===========================================================================
def strip_comments(text):
    text = re.sub(r"/\*.*?\*/", " ", text, flags=re.DOTALL)   # block comments
    text = re.sub(r"//[^\n]*", " ", text)                     # line comments
    return text


_KEYWORDS = {
    "module", "endmodule", "input", "output", "inout", "wire", "reg", "tri",
    "supply0", "supply1", "assign", "parameter", "localparam", "specify",
    "endspecify", "generate", "endgenerate", "always", "initial", "function",
    "endfunction", "task", "endtask", "defparam",
}


def parse_module_header(text):
    """Return (module_name, [port_names_in_order])."""
    m = re.search(r"\bmodule\s+([\\A-Za-z_][\w$]*)\s*\((.*?)\)\s*;",
                  text, flags=re.DOTALL)
    if not m:
        raise ValueError("No 'module NAME ( ... );' header found.")
    name = m.group(1)
    body = m.group(2)
    ports = [p.strip() for p in body.split(",") if p.strip()]
    return name, ports, m.end()


def parse_port_widths(text):
    """Map port name -> (msb, lsb) or None for scalar, from input/output/inout
    declarations."""
    widths = {}
    decl_re = re.compile(
        r"\b(input|output|inout)\b\s*(?:\[\s*(\d+)\s*:\s*(\d+)\s*\])?\s*"
        r"([\\A-Za-z_][\w$]*)\s*;")
    for m in decl_re.finditer(text):
        _, msb, lsb, nm = m.groups()
        if msb is None:
            widths[nm] = None
        else:
            widths[nm] = (int(msb), int(lsb))
    return widths


def expand_top_ports(ports, widths):
    """Expand bus ports into per-bit net names, preserving module port order."""
    expanded = []
    for p in ports:
        w = widths.get(p)
        if w is None:
            expanded.append(p)
        else:
            msb, lsb = w
            step = -1 if msb >= lsb else 1
            for i in range(msb, lsb + step, step):
                expanded.append("%s[%d]" % (p, i))
    return expanded


# instance head:  CELL  INST  (
_INST_HEAD_RE = re.compile(
    r"([\\A-Za-z_][\w$]*)\s+(\\\S+|[A-Za-z_][\w$]*(?:\[\d+\])?)\s*\(")
# a single named connection:  .PORT ( expr )
_CONN_RE = re.compile(r"\.\s*([\w$]+(?:\[\d+\])?)\s*\(\s*(.*?)\s*\)",
                      flags=re.DOTALL)


def find_instances(text):
    """Yield (cell, inst, body) for each instance. Skips module/decls."""
    i, n = 0, len(text)
    for m in _INST_HEAD_RE.finditer(text):
        cell = m.group(1)
        inst = m.group(2)
        if cell in _KEYWORDS:
            continue
        # scan from the '(' to its matching ')'
        depth = 0
        j = m.end() - 1            # position of '('
        start = m.end()            # first char inside
        k = j
        while k < n:
            c = text[k]
            if c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
                if depth == 0:
                    body = text[start:k]
                    yield cell, inst, body
                    break
            k += 1


def split_concat(expr):
    """Return list of scalar net tokens for an expr that may be a {..} concat."""
    expr = expr.strip()
    if expr.startswith("{") and expr.endswith("}"):
        inner = expr[1:-1]
        return [t.strip() for t in inner.split(",") if t.strip()]
    return [expr]


def norm_net(tok, pwr, gnd):
    """Normalise a single net token; map constants to rails."""
    tok = tok.strip()
    m = re.match(r"^\d*'[bB]([01xzXZ]+)$", tok)
    if m:
        bits = m.group(1)
        if len(bits) == 1:
            return pwr if bits == "1" else gnd
        # multi-bit constant in a scalar slot: fall back, keep literal-ish
        return gnd
    return tok


# ===========================================================================
#  Translation
# ===========================================================================
def translate(args):
    rail_names = set(x.upper() for x in args.rail_names)
    railmap = {}
    for spec in args.tie:
        k, _, v = spec.partition("=")
        railmap[k.strip().upper()] = v.strip()
    # defaults if user didn't override
    railmap.setdefault("VNW", args.pos_pwr)
    railmap.setdefault("VPW", args.neg_pwr)

    libmap = []
    for spec in args.map_lib:
        a, _, b = spec.partition("=")
        libmap.append((a.strip(), b.strip()))

    # Real CDLs get .INCLUDE'd; black-box CDLs are parsed for their pin
    # interface only and emitted as empty .SUBCKT stubs (macro handling).
    subckts = {}
    bb = parse_cdl(args.blackbox_cdl, rail_names)
    subckts.update(bb)
    real = parse_cdl(args.cdl, rail_names)
    subckts.update(real)                      # a real -c definition always wins
    blackbox_names = set(bb) - set(real)      # names only known as black boxes
    if not subckts:
        sys.exit("ERROR: no .SUBCKT found in the supplied CDL/SPICE file(s).")

    raw = open(args.verilog, "r", errors="replace").read()
    text = strip_comments(raw)

    mod_name, ports, _ = parse_module_header(text)
    widths = parse_port_widths(text)
    top_ports = expand_top_ports(ports, widths)
    port_set = set(top_ports) | set(ports)

    # assign a = b (scalar nets or bus bits): the two nets are one. An internal net is renamed to the other
    # net. When both are ports, a marker resistor RASSIGN<n> joins them: SPICE cannot short two subckt ports,
    # and the LVS deck (gf180mcu.lvs) joins the two nets of every ASSIGN* resistor and removes it.
    parent = {}
    def _find(x):
        while parent.get(x, x) != x:
            x = parent[x]
        return x
    n_assign = 0
    for am in re.finditer(r"\bassign\s+([^=;]+?)\s*=\s*([^;]+?)\s*;", text):
        lhs = norm_net(am.group(1), args.pos_pwr, args.neg_pwr)
        rhs = norm_net(am.group(2), args.pos_pwr, args.neg_pwr)
        if any(c in lhs + rhs for c in "{}()~&|^?+-") or ":" in lhs + rhs:
            sys.stderr.write("WARN: assign not a plain net: %s = %s (ignored)\n" % (lhs, rhs))
            continue
        a, b = _find(lhs), _find(rhs)
        if a != b:
            parent[a] = b
        n_assign += 1
    groups = {}
    for x in list(parent):
        groups.setdefault(_find(x), set()).add(x)
    for r, g in groups.items():
        g.add(r)
    alias = {}
    assign_lines = []
    rails = {args.pos_pwr, args.neg_pwr}
    for g in groups.values():
        fixed = sorted(x for x in g if x in port_set or x in rails)
        rep_net = fixed[0] if fixed else sorted(g)[0]
        for x in g:
            if x == rep_net:
                continue
            if x in port_set or x in rails:
                assign_lines.append("RASSIGN%d %s %s 0" % (len(assign_lines) + 1, rep_net, x))
            else:
                alias[x] = rep_net

    # decide which rail nets need .GLOBAL (used but not already a top port)
    def resolve_rail_net(pin):
        base = _pin_base(pin).upper()
        return railmap.get(base, pin)

    out = []
    inst_lines = []
    n_inst = 0
    missing_cells = {}       # cell -> count
    unconn = 0
    used_libs = set()
    global_nets = set()

    for cell, inst, body in find_instances(text):
        # optional library-token remap (e.g. verification alias 7t->9t)
        lookup = cell
        for a, b in libmap:
            if a in lookup:
                lookup = lookup.replace(a, b)
        sc = subckts.get(lookup.lower())
        if sc is None:
            missing_cells[cell] = missing_cells.get(cell, 0) + 1
            continue

        # gather named connections
        conn = {}            # pin name (exact subckt spelling) -> net
        for cm in _CONN_RE.finditer(body):
            port = cm.group(1)
            expr = cm.group(2)
            nets = [norm_net(t, args.pos_pwr, args.neg_pwr)
                    for t in split_concat(expr)]
            # exact scalar pin?
            if port in sc.pins:
                conn[port] = nets[0]
                continue
            # bus base?
            bits = bus_bits(sc, port)
            if bits:
                if len(bits) == len(nets):
                    for (idx, pinname), net in zip(bits, nets):
                        conn[pinname] = net
                else:
                    # length mismatch: connect what we can, warn
                    for (idx, pinname), net in zip(bits, nets):
                        conn[pinname] = net
                    sys.stderr.write(
                        "WARN: %s .%s width %d != pins %d\n"
                        % (inst, port, len(nets), len(bits)))
                continue
            # bit-select named port .Q[3] ( net )
            if port in sc.pins:
                conn[port] = nets[0]
                continue
            # unknown port name on this cell -> keep as scalar (best effort)
            conn[port] = nets[0]

        conn = {k: alias.get(v, v) for k, v in conn.items()}
        # emit nets in subckt pin order
        row = []
        for pin in sc.pins:
            if pin in conn:
                row.append(conn[pin])
            elif pin in sc.rails:
                net = resolve_rail_net(pin)
                row.append(net)
                if net not in port_set:
                    global_nets.add(net)
            else:
                # a real signal pin left unconnected in the Verilog
                dangling = "%s__%s__UNCONN" % (inst, pin)
                row.append(dangling)
                unconn += 1

        used_libs.add(lookup.lower())
        xname = inst if inst[:1] in ("x", "X") else "X" + inst
        inst_lines.append(_wrap_x(xname, row, sc.name))
        n_inst += 1

    # ---- assemble output ----
    out.append("*")
    out.append("*  %s : SPICE netlist translated from Verilog netlist %s"
               % (os.path.basename(args.output), os.path.basename(args.verilog)))
    out.append("*  generated %s by verilog2spice.py"
               % datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    out.append("*  top module : %s" % mod_name)
    out.append("*  rail map   : " + ", ".join("%s->%s" % (k, v)
                                               for k, v in sorted(railmap.items())))
    out.append("*" + "-" * 70)
    out.append("")
    inc_mode = "relto" if args.include_relto else args.include_mode
    for c in args.cdl:
        inc = format_include(c, inc_mode, args.include_relto)
        if inc is not None:
            out.append(".INCLUDE %s" % inc)
    out.append("")

    # Black-boxed macros: interface-only stubs so the top schematic reads
    # cleanly. Compare these as black boxes and LVS each macro separately.
    bb_used = [subckts[n] for n in sorted(used_libs) if n in blackbox_names]
    if bb_used:
        out.append("* ---- black-boxed macros (interface only; LVS separately) ----")
        for scb in bb_used:
            out.append(".SUBCKT %s %s" % (scb.name, " ".join(scb.pins)))
            out.append(".ENDS %s" % scb.name)
        out.append("")
    # .GLOBAL: the rails that are not exposed as top-level ports
    globals_needed = [args.pos_pwr, args.neg_pwr]
    for g in sorted(global_nets):
        if g not in globals_needed:
            globals_needed.append(g)
    # only declare globals that are not module ports (VDD/VSS are ports here)
    glob = [g for g in globals_needed if g not in port_set]
    if glob:
        out.append(".GLOBAL " + " ".join(glob))
        out.append("")

    out.append(".SUBCKT %s %s" % (mod_name, " ".join(top_ports)))
    out.extend(inst_lines)
    out.extend(assign_lines)
    out.append(".ENDS %s" % mod_name)
    out.append("")

    with open(args.output, "w") as fh:
        fh.write("\n".join(out))

    # ---- report ----
    r = sys.stderr.write
    r("\n=== verilog2spice summary ===\n")
    r("  subckts parsed from CDL : %d\n" % len(subckts))
    r("  instances translated    : %d\n" % n_inst)
    r("  distinct cells used      : %d\n" % len(used_libs))
    if n_assign:
        r("  assign statements        : %d (%d nets renamed, %d ASSIGN resistors between ports)\n"
          % (n_assign, len(alias), len(assign_lines)))
    if unconn:
        r("  unconnected signal pins  : %d  (tied to per-instance *_UNCONN nets)\n"
          % unconn)
    if missing_cells:
        tot = sum(missing_cells.values())
        r("  MISSING from CDL         : %d instances across %d cell types:\n"
          % (tot, len(missing_cells)))
        for c in sorted(missing_cells):
            r("       %-45s x%d\n" % (c, missing_cells[c]))
        r("  -> add the CDL(s) that define these (e.g. the SRAM/IO libs) with -c\n")
    r("  output written           : %s\n" % args.output)
    return 0 if not missing_cells else 2


def _wrap_x(xname, nets, cell, width=118):
    """Format an X instance line, wrapping with '+' if very long."""
    toks = [xname] + nets + [cell]
    lines = []
    cur = toks[0]
    for t in toks[1:]:
        if len(cur) + 1 + len(t) > width:
            lines.append(cur)
            cur = "+ " + t
        else:
            cur += " " + t
    lines.append(cur)
    return "\n".join(lines)


# ===========================================================================
#  CLI
# ===========================================================================
def build_argparser():
    p = argparse.ArgumentParser(
        description="Structured Verilog -> SPICE netlist translator "
                    "(gf180mcu-aware).")
    p.add_argument("-v", "--verilog", dest="verilog",
                   help="input structural Verilog netlist")
    p.add_argument("-c", "--cdl", dest="cdl", action="append", default=[],
                   help="reference CDL/SPICE library, .INCLUDE'd in the output "
                        "(repeatable)")
    p.add_argument("--blackbox-cdl", dest="blackbox_cdl", action="append",
                   default=[], metavar="CDL",
                   help="CDL whose cells are BLACK-BOXED: parsed for pin order "
                        "but emitted as empty .SUBCKT stubs and NOT .INCLUDE'd "
                        "(use for hard macros like SRAM/IO). Repeatable.")
    p.add_argument("-o", "--output", dest="output",
                   help="output SPICE netlist")
    p.add_argument("--pos-pwr", dest="pos_pwr", default="VDD",
                   help="positive supply net name (default VDD)")
    p.add_argument("--neg-pwr", dest="neg_pwr", default="VSS",
                   help="negative supply net name (default VSS)")
    p.add_argument("--tie", action="append", default=[], metavar="PIN=NET",
                   help="tie an implicit rail pin to a net "
                        "(default VNW=VDD, VPW=VSS). Repeatable.")
    p.add_argument("--rail-name", dest="rail_names", action="append",
                   default=sorted(DEFAULT_RAIL_NAMES), metavar="NAME",
                   help="additional pin name to treat as a rail")
    p.add_argument("--map-lib", dest="map_lib", action="append", default=[],
                   metavar="FROM=TO",
                   help="rewrite a substring of the cell name before CDL lookup "
                        "(e.g. mcu7t5v0=mcu9t5v0 to verify against the 9-track "
                        "CDL). Repeatable.")
    p.add_argument("--include-mode", dest="include_mode",
                   choices=["abs", "asis", "basename", "none"], default="abs",
                   help="how to write .INCLUDE paths for the CDLs: abs (default, "
                        "safest for LVS), asis (as passed on -c), basename, or "
                        "none (emit no .INCLUDE lines).")
    p.add_argument("--include-relto", dest="include_relto", metavar="DIR",
                   default=None,
                   help="write .INCLUDE paths relative to DIR (e.g. the folder "
                        "the .sp will live in). Overrides --include-mode.")
    # legacy-compatible aliases
    p.add_argument("-spice", dest="cdl_legacy", action="append", default=[],
                   help=argparse.SUPPRESS)
    p.add_argument("-verilog", dest="verilog_legacy", help=argparse.SUPPRESS)
    p.add_argument("-output", dest="output_legacy", help=argparse.SUPPRESS)
    p.add_argument("-pos_pwr", dest="pos_pwr_legacy", help=argparse.SUPPRESS)
    p.add_argument("-neg_pwr", dest="neg_pwr_legacy", help=argparse.SUPPRESS)
    p.add_argument("-delimiter", dest="delimiter", action="store_true",
                   help=argparse.SUPPRESS)
    return p


def main(argv):
    args = build_argparser().parse_args(argv)
    # fold legacy flags
    if args.verilog_legacy:
        args.verilog = args.verilog_legacy
    if args.output_legacy:
        args.output = args.output_legacy
    if args.cdl_legacy:
        args.cdl += args.cdl_legacy
    if args.pos_pwr_legacy:
        args.pos_pwr = args.pos_pwr_legacy
    if args.neg_pwr_legacy:
        args.neg_pwr = args.neg_pwr_legacy

    if not args.cdl and not args.blackbox_cdl:
        sys.exit("ERROR: no CDL specified (use -c / -spice / --blackbox-cdl).")
    if not args.verilog:
        sys.exit("ERROR: no Verilog specified (use -v / -verilog).")
    if not args.output:
        sys.exit("ERROR: no output specified (use -o / -output).")
    return translate(args)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))