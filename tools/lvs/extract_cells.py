# Cell-level netlist of a placed standard-cell block (klayout -b -r, -rd input= top= output=).
# Every standard cell instance in the tree of `top` (also inside sub-macros) becomes one Verilog instance; its
# pins are probed on Metal1 at the pin labels of the cell, nets come from metal + via connectivity of the
# flattened block, Metal1 joined to poly through contacts. Net names: the label of the top cell on that net, else n<id>. Supplies, fillers, taps,
# endcaps and antenna diodes are left out. Cell name prefixes of LibreLane macros (XX_) are removed.
import pya, re, collections
ly = pya.Layout(); ly.read(input)
c0 = ly.cell(top)
SKIP = re.compile(r"__(fill|fillcap|filltie|endcap|antenna)")
SUPPLY = {"VDD", "VSS", "VNW", "VPW"}
def base(n): return re.sub(r"^[A-Z0-9]{2}_(?=gf180mcu_fd_sc)", "", n)
# 1. standard cell instances with their full transformation and pin label points
insts = []
it = pya.RecursiveInstanceIterator(ly, c0)
while not it.at_end():
    cell = it.inst_cell()
    if "gf180mcu_fd_sc" in cell.name and not SKIP.search(cell.name):
        t = it.trans() * it.inst_trans()
        pins = {}
        for li in ly.layer_indexes():
            info = ly.get_info(li)
            if info.layer == 34 and info.datatype == 10:
                for s in cell.shapes(li).each():
                    if s.is_text() and s.text.string not in SUPPLY:
                        pins.setdefault(s.text.string, t * s.text.position())
        insts.append((base(cell.name), pins))
        it.unselect_cell() if hasattr(it, "unselect_cell") else None
    it.next()
print("standard cell instances (logic):", len(insts), collections.Counter(n for n, _ in insts).most_common(6))
# 2. flat connectivity of metal + vias
flat = pya.Layout(); flat.dbu = ly.dbu
fc = flat.create_cell(top); fc.copy_tree(c0); fc.flatten(-1, True)
MET = [("M1", 34), ("M2", 36), ("M3", 42), ("M4", 46), ("M5", 81)]
VIA = [("V1", 35, "M1", "M2"), ("V2", 38, "M2", "M3"), ("V3", 40, "M3", "M4"), ("V4", 41, "M4", "M5")]
l2n = pya.LayoutToNetlist(pya.RecursiveShapeIterator(flat, fc, []))
L = {n: l2n.make_layer(flat.layer(d, 0), n) for n, d in MET}
for n in L: l2n.connect(L[n])
for v, d, a, b in VIA:
    lv = l2n.make_layer(flat.layer(d, 0), v); l2n.connect(lv); l2n.connect(L[a], lv); l2n.connect(lv, L[b])
# poly through contacts: the fingers of one pin of a wide cell (inv_8 I) are Metal1 pieces joined by the gate
# poly. Diffusion stays out, so source and drain are not joined through a transistor.
po = l2n.make_layer(flat.layer(30, 0), "PO"); co = l2n.make_layer(flat.layer(33, 0), "CO")
l2n.connect(po); l2n.connect(co); l2n.connect(L["M1"], co); l2n.connect(co, po)
l2n.extract_netlist()
lab2met = {d: n for n, d in MET}
names = collections.defaultdict(set)
for li in ly.layer_indexes():
    info = ly.get_info(li)
    if info.datatype != 10 or info.layer not in lab2met: continue
    for s in c0.shapes(li).each():
        if s.is_text() and s.text.string not in SUPPLY | {"dVDD", "dVSS"}:
            n = l2n.probe_net(L[lab2met[info.layer]], s.text.position())
            if n: names[n.cluster_id].add(s.text.string)
def netname(cid):
    ns = sorted(names.get(cid, ()))
    return ns[0] if ns else "n%d" % cid
alias = [sorted(v) for v in names.values() if len(v) > 1]
if alias: print("ports shorted together in the layout:", alias)
ports = sorted(set(x for v in names.values() for x in v))
lines, used, floating = [], set(), 0
for i, (cn, pins) in enumerate(insts):
    conns = []
    for p, pt in sorted(pins.items()):
        n = l2n.probe_net(L["M1"], pt)
        if n is None: floating += 1; continue
        nn = netname(n.cluster_id); used.add(nn)
        conns.append(".%s(%s)" % (p, "\\" + nn + " " if not re.match(r"^[A-Za-z_]\w*$", nn) else nn))
    lines.append("  %s u%d (%s);" % (cn, i, ", ".join(conns)))
wires = sorted(x for x in used if x not in ports)
with open(output, "w") as f:
    f.write("// cell-level netlist extracted from the layout of %s\nmodule %s (%s);\n" % (top, top, ", ".join(ports)))
    for p in ports: f.write("  inout %s;\n" % p)
    for w in wires: f.write("  wire %s;\n" % w)
    f.write("\n".join(lines) + "\nendmodule\n")
print("ports %d, wires %d, unprobed pins %d -> %s" % (len(ports), len(wires), floating, output))
