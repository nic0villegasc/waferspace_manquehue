# Structural compare of two flat cell-level Verilog netlists (written by yosys write_verilog), as graphs of
# standard cells (klayout -b -r, -rd gold= gate= top=). Buffers (buf_*) are removed (input and output nets
# merged), tie cells become the constants 1'b1 / 1'b0, and assign statements are aliases. Cells are compared
# by type and pin connections with KLayout's NetlistComparer; ports are matched by name.
import pya, re, collections
def parse(path):
    txt = open(path).read()
    txt = re.sub(r"/\*.*?\*/", "", txt, flags=re.S)
    txt = re.sub(r"\(\*.*?\*\)", "", txt, flags=re.S)
    m = re.search(r"module\s+\S+\s*\((.*?)\);(.*?)endmodule", txt, re.S)
    body = m.group(2)
    ports = []
    for d, rest in re.findall(r"^\s*(input|output|inout)\s+(.*?);", body, re.M):
        ports += [x.strip() for x in rest.split(",") if x.strip()]
    parent = {}
    def find(x):
        while parent.get(x, x) != x:
            parent[x] = parent.get(parent[x], parent[x]); x = parent[x]
        return x
    def union(a, b):
        a, b = find(a), find(b)
        if a != b: parent[b] = a
    norm = lambda s: s.strip().replace("1'h1", "1'b1").replace("1'h0", "1'b0")
    for a, b in re.findall(r"^\s*assign\s+(.+?)\s*=\s*(.+?);", body, re.M):
        union(norm(b), norm(a))
    cells = []
    for typ, name, conns in re.findall(r"^\s*(\S+)\s+(\S+)\s*\((.*?)\);", body, re.M | re.S):
        if typ in ("input", "output", "inout", "wire", "assign", "module", "reg"): continue
        pins = dict((p, norm(n)) for p, n in re.findall(r"\.(\w+)\s*\(\s*(.*?)\s*\)\s*(?:,|$)", conns, re.S))
        cells.append((re.sub(r"^\\", "", typ), pins))
    out = []
    for typ, pins in cells:
        short = typ.split("__")[-1]
        if re.match(r"buf_\d+$", short) or re.match(r"clkbuf_\d+$", short):
            union(pins.get("I"), pins.get("Z")); continue
        if short == "tieh": union("1'b1", pins.get("Z")); continue
        if short == "tiel": union("1'b0", pins.get("ZN", pins.get("Z"))); continue
        out.append((typ, pins))
    # port nets win as representative names
    for p in ports: 
        r = find(p)
        if r != p: parent[r] = p; parent[p] = p
    return ports, [(t, {k: find(v) for k, v in pins.items()}) for t, pins in out], find
def build(ports, cells, pinsets):
    nl = pya.Netlist()
    proto = {}
    for t, pins in sorted(pinsets.items()):
        c = pya.Circuit(); c.name = t; nl.add(c)
        for p in pins: c.create_pin(p)
        proto[t] = c
    top = pya.Circuit(); top.name = "TOP"; nl.add(top)
    nets = {}
    def net(n):
        if n not in nets:
            nets[n] = top.create_net(n)
        return nets[n]
    for p in sorted(ports):
        pin = top.create_pin(p); top.connect_pin(pin, net(p))
    for i, (t, pins) in enumerate(cells):
        sc = top.create_subcircuit(proto[t], "c%d" % i)
        for pd in proto[t].each_pin():
            n = pins.get(pd.name())
            if n: sc.connect_pin(pd, net(n))
    return nl
gp, gc, _ = parse(gold); lp, lc, _ = parse(gate)
pinsets = collections.defaultdict(set)
for t, pins in gc + lc: pinsets[t] |= set(pins)
pinsets = {t: sorted(s) for t, s in pinsets.items()}
print("gold: %d cells, layout: %d cells (after removing buffers and ties)" % (len(gc), len(lc)))
ct = lambda cs: collections.Counter(t.split("__")[-1] for t, _ in cs)
a, b = ct(gc), ct(lc)
for t in sorted(set(a) | set(b)):
    if a[t] != b[t]: print("   cell count differs: %-10s source %d, layout %d" % (t, a[t], b[t]))
na, nb = build(gp, gc, pinsets), build(lp, lc, pinsets)
cmp = pya.NetlistComparer()
for t in pinsets: cmp.same_circuits(na.circuit_by_name(t), nb.circuit_by_name(t))
logger = pya.GenericNetlistCompareLogger() if hasattr(pya, "GenericNetlistCompareLogger") else None
xref = pya.NetlistCrossReference()
ok = cmp.compare(na, nb, xref)
print("STRUCTURE", "MATCH" if ok else "MISMATCH")
if not ok:
    for cp in xref.each_circuit_pair():
        if cp.first() and cp.first().name == "TOP":
            bad = [(n.first().name if n.first() else "-", n.second().name if n.second() else "-") for n in xref.each_net_pair(cp) if str(n.status()) not in ("Match", "MatchWithWarning")]
            print("   unmatched nets: %d" % len(bad)); [print("     source %-30s layout %s" % x) for x in bad[:40]]
            bs = [(s.first().name if s.first() else "-", s.second().name if s.second() else "-") for s in xref.each_subcircuit_pair(cp) if str(s.status()) != "Match"]
            print("   unmatched cells: %d" % len(bs))
