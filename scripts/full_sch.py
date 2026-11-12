#!/usr/bin/env python3
"""Chip schematic with the DC-DC for the full-chip LVS (scripts/lvs_full.sh).
usage: full_sch.py <chip_top.pnl.v> <out chip_full.v>
The DC-DC pads of the LibreLane netlist have only their supply pins. Here their core pins are wired to the
DC-DC blocks by name, and the blocks are added: DB_V0 (digital), VCOs_wrapper, 3 x Seg8_PS_V0 (power stages).
Name rules (design intent, not the layout):
  pad_<X> input pad  -> Y to the DB_V0 port of the same name (case-insensitive), IE to DB_DVDD, rest to VSS
  pad_<X> output pad -> A from the DB_V0 port of the same name, OE to DB_DVDD, rest to VSS
  DB_V0 CHk_Vsij <-> Seg8_PS_V0 #k Vsij; Seg8 #k: Vc = PSk_Vc, VDD_HB = PSk_VDD, VSS_HB = VSS
  Seg8 GD_VDD = GD2_VDD and GD3_VDD (one net: the DC-DC joins them), GD_VSS = VSS
  VCOs_wrapper: V_REF, V_FB from their pads, VDD = VCO_VDD, VSS = VSS, VCOF/VCOR to DB_V0 VCOF/VCOR
  DB_V0 dVDD = DB_DVDD, dVSS = VSS
"""
import re, sys
pnl, out = sys.argv[1], sys.argv[2]
INPUTS = ["CH1_in1", "CH1_in2", "CH2_in1", "CH2_in2", "CH3_in1", "CH3_in2", "CH_out_sel0", "CH_out_sel1",
          "CH_sel", "Seg_sel0", "Seg_sel1", "PWM_sel", "VCO_sel"]
OUTPUTS = ["CHx_PD", "CHx_VCOF", "CHx_VCOR", "CHx_Vs1", "CHx_Vs2"]
db = lambda n: "dc_" + n.upper()
s = open(pnl).read()
s = "\n".join(l for l in s.split("\n") if "gf180mcu_ws_ip__" not in l)
def rewire(name, conns):
    global s
    pat = re.compile(r"(gf180mcu_fd_io__bi_24t\s+pad_%s\s*\()(.*?)(\);)" % re.escape(name), re.S)
    m = pat.search(s); assert m, name
    keep = re.findall(r"\.(DVDD|DVSS|VDD|VSS|PAD)\(([^)]*)\)", m.group(2))
    new = ", ".join(".%s(%s)" % kv for kv in keep) + ", " + ", ".join(".%s(%s)" % kv for kv in conns)
    s = s[:m.start()] + m.group(1) + new + m.group(3) + s[m.end():]
for n in INPUTS:
    rewire(n, [("Y", db(n)), ("IE", "DB_DVDD"), ("OE", "VSS"), ("A", "VSS"), ("CS", "VSS"), ("PD", "VSS"), ("PU", "VSS"), ("SL", "VSS")])
for n in OUTPUTS:
    rewire(n, [("A", db(n)), ("OE", "DB_DVDD"), ("IE", "VSS"), ("CS", "VSS"), ("PD", "VSS"), ("PU", "VSS"), ("SL", "VSS")])
s = re.sub(r"\bGD3_VDD\b", "GD2_VDD", s)
VS = ["Vs%d%d" % (i, j) for i in (1, 2) for j in range(1, 9)]
inst = ["  // DC-DC blocks (scripts/lvs_full.sh)"]
dbp = {"VDD": "DB_DVDD", "VSS": "VSS", "VCOF": "dc_VCOF", "VCOR": "dc_VCOR"}
for n in INPUTS + OUTPUTS:
    port = n.replace("_in", "_IN") if re.match(r"CH\d_in\d", n) else n
    dbp[port] = db(n)
for k in (1, 2, 3):
    for v in VS: dbp["CH%d_%s" % (k, v)] = "dc_CH%d_%s" % (k, v)
inst.append("  DB_V0 dcdc_db (%s);" % ", ".join(".%s(%s)" % kv for kv in sorted(dbp.items())))
inst.append("  VCOs_wrapper dcdc_vco (.VDD(VCO_VDD), .VSS(VSS), .V_FB(V_FB), .V_REF(V_REF), .VCOR(dc_VCOR), .VCOF(dc_VCOF));")
for k in (1, 2, 3):
    c = {"Vc": "PS%d_Vc" % k, "VDD_HB": "PS%d_VDD" % k, "VSS_HB": "VSS", "GD_VDD": "GD2_VDD", "GD_VSS": "VSS"}
    for v in VS: c[v] = "dc_CH%d_%s" % (k, v)
    inst.append("  Seg8_PS_V0 dcdc_ps%d (%s);" % (k, ", ".join(".%s(%s)" % kv for kv in sorted(c.items()))))
wires = sorted(set(re.findall(r"\bdc_\w+", "\n".join(inst))))
s = re.sub(r"\nendmodule\s*$", "\n  wire %s;\n%s\nendmodule\n" % (", ".join(wires), "\n".join(inst)), s.rstrip() + "\n", count=1)
open(out, "w").write(s)
print("chip schematic with DC-DC: %d pad rewires, DB_V0 %d ports, %d new nets -> %s" % (len(INPUTS) + len(OUTPUTS), len(dbp), len(wires), out))
