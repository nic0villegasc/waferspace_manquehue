# Pad labels for KLayout: a GDS with every pad of padring.txt as an outline and its number and signal as polygon
# text outside the die, next to the pad, in chip coordinates (make labels). make view opens it over a chip GDS
# with colours (out/view.lyp); by hand: File > Open, "Add to current panel".
# usage: klayout -b -r scripts/pad_labels.py -rd ring=padring.txt -rd cfg=librelane/pad_cfg.tcl -rd out=<gds>
# Layers per kind (0 CROC signal, 1 CROC supply, 2 unused, 3 DC-DC signal, 4 DC-DC supply, 5 breaker):
#         200/<kind> pad outline, 201/<kind> text.
import re
import pya

DIE_W, DIE_H, PAD_W, PAD_D, EDGE, TEXT_H = 1936.0, 5122.0, 75.0, 350.0, 26.0, 22.0
KIND = {"croc": 0, "croc_sup": 1, "unused": 2, "dcdc": 3, "dcdc_sup": 4, "brk": 5}

sig, seg = {}, {}
for line in open(ring):
    f = line.split()
    if f[:1] == ["pad"]:
        sig[f[2]] = (int(f[1]), f[3])
    elif f[:1] == ["seg"]:
        for r in f[2:]:
            lo, _, hi = r.partition("-")
            for n in range(int(lo), int(hi or lo) + 1):
                seg[n] = f[1]

ly = pya.Layout()
ly.dbu = 0.001
top = ly.create_cell("pad_labels")
box_layer = {k: ly.layer(200, v) for k, v in KIND.items()}
text_layer = {k: ly.layer(201, v) for k, v in KIND.items()}
GAP = 15.0                         # um between the die edge and the text
gen = pya.TextGenerator.default_generator()
unit = gen.text("X", ly.dbu, 1.0).bbox().height() * ly.dbu      # glyph height in um at magnification 1


def text(s, kind, side, along):
    """Polygon text of height TEXT_H outside the die, at the pad's position along its side."""
    r = gen.text(s, ly.dbu, TEXT_H / unit)
    if side in ("NORTH", "SOUTH"):
        r.transform(pya.Trans(pya.Trans.R90))          # reads bottom to top
    b = r.bbox()
    g, a = int(GAP / ly.dbu), int(along / ly.dbu)
    if side == "WEST":
        r.move(-g - b.right, a - b.center().y)
    elif side == "EAST":
        r.move(int(DIE_W / ly.dbu) + g - b.left, a - b.center().y)
    elif side == "SOUTH":
        r.move(a - b.center().x, -g - b.top)
    else:
        r.move(a - b.center().x, int(DIE_H / ly.dbu) + g - b.bottom)
    top.shapes(text_layer[kind]).insert(r)


for m in re.finditer(r"place_pad -row IO_(\w+) -location ([\d.]+) (\S+) -master \S+?__(\w+)", open(cfg).read()):
    side, loc, inst, master = m.group(1), float(m.group(2)), m.group(3), m.group(4)
    w = 5.0 if master == "brk5" else PAD_W
    x0, y0, x1, y1 = {"WEST": (EDGE, loc, EDGE + PAD_D, loc + w), "EAST": (DIE_W - EDGE - PAD_D, loc, DIE_W - EDGE, loc + w),
                      "SOUTH": (loc, EDGE, loc + w, EDGE + PAD_D), "NORTH": (loc, DIE_H - EDGE - PAD_D, loc + w, DIE_H - EDGE)}[side]
    name = inst[4:] if inst.startswith("pad_") else inst
    num, cell = sig.get(name, (0, master))
    supply = cell in ("dvdd", "dvss")
    if master == "brk5":
        kind = "brk"
    elif seg.get(num) == "VDD":
        kind = "unused" if name.startswith("unused") else "croc_sup" if supply else "croc"
    else:
        kind = "dcdc_sup" if supply else "dcdc"
    top.shapes(box_layer[kind]).insert(pya.DBox(x0, y0, x1, y1))
    if kind != "brk":
        text("%d %s" % (num, name), kind, side, (y0 + y1) / 2 if side in ("WEST", "EAST") else (x0 + x1) / 2)

ly.write(out)
print("wrote %s" % out)
