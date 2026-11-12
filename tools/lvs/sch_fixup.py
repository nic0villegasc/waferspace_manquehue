# Fix-ups of a folded schematic: *_dw device names in the DNWELL subckts, and the calls of subckts whose
# definition lost pins (VPW folded) get the same pins removed. usage: sch_fixup.py in out "<dw list>" <original>
import re, sys
inp, out, orig = sys.argv[1], sys.argv[2], sys.argv[4]
# DNWELL list: "subckt" (nmos and pmos) or "subckt:nmos" / "subckt:pmos"
dw = {}
for x in (y for y in sys.argv[3].split(",") if y):
    n, _, d = x.lower().partition(":")
    dw[n] = (d,) if d else ("nmos", "pmos")
RN = dict(x.split("=") for x in (sys.argv[5] if len(sys.argv) > 5 else "").split(",") if x)
def subckts(path):
    d = {}
    for l in open(path):
        t = l.split()
        if t and t[0].lower() == ".subckt": d[t[1].lower()] = [p.upper() for p in t[2:]]
    return d
before, after = subckts(orig), subckts(inp)
lines = open(inp).read().split("\n")
# 0 V sources (ammeters of the schematic) are wires: their second net is renamed to the first in that subckt
amm, cur = {}, None
for l in lines:
    t = l.split()
    if t and t[0].lower() == ".subckt": cur = t[1].lower()
    if t and t[0][:1] in "vV" and len(t) >= 4 and re.match(r"^(dc\s+)?0+(\.0*)?$", " ".join(t[3:]).lower().replace("dc ", "")):
        amm.setdefault(cur, {})[t[2]] = t[1]
merged, cur = [], None
for l in lines:
    t = l.split()
    if t and t[0].lower() == ".subckt": cur = t[1].lower()
    if t and t[0][:1] in "vV" and cur in amm and t[2] in amm[cur]: continue
    if cur in amm and t and not t[0].startswith("*"):
        l = " ".join(amm[cur].get(x, x) if i > 0 else x for i, x in enumerate(t))
    merged.append(l)
lines, res, cur = merged, [], None
for l in lines:
    t = l.split(); low = l.lower()
    if t and t[0].lower() == ".subckt": cur = t[1].lower()
    elif t and t[0].lower().startswith("x") and len(t) > 2:
        name = t[-1].lower()
        if name in before and name in after and len(before[name]) != len(after[name]) and len(t) - 2 == len(before[name]):
            keep = [i for i, p in enumerate(before[name]) if p in after[name]]
            l = " ".join([t[0]] + [t[1 + i] for i in keep] + [t[-1]])
    if cur in dw and t and not t[0].startswith(("*", ".")):
        for d in dw[cur]:
            l = re.sub(r"\b(%s_5p0)\b" % d, r"\1_dw", l)
    res.append(l)
txt = "\n".join(res)
for a, b in RN.items():
    txt = re.sub(r"\b%s\b" % re.escape(a), b, txt)
open(out, "w").write(txt)
