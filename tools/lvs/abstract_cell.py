# Reduce cell `cell` of a GDS to a pin-only abstract for chip-level LVS (klayout -b -r, -rd input= output= cell= top=).
# Child instances go, and on each layer only the shapes of the cell itself that contain a pin label of the same layer
# number stay, with the labels. The macro is checked by its own LVS; the chip LVS checks only what touches its pins.
# Needed because KLayout 0.30.9 deep-mode extraction crashes (malloc) on the full croc_soc inside chip_top.
import pya
ly = pya.Layout(); ly.read(input)
c = ly.cell(cell)
for inst in list(c.each_inst()):
    inst.delete()
pts = {}
for li in ly.layer_indexes():
    for s in c.shapes(li).each():
        if s.is_text():
            pts.setdefault(ly.get_info(li).layer, []).append(s.text.position())
kept = 0
for li in ly.layer_indexes():
    p = pts.get(ly.get_info(li).layer, [])
    sh = c.shapes(li)
    polys = [s.polygon for s in sh.each() if not s.is_text() and s.polygon and any(s.bbox().contains(q) for q in p)]
    texts = [s.text for s in sh.each() if s.is_text()]
    sh.clear()
    for q in polys: sh.insert(q)
    for t in texts: sh.insert(t)
    kept += len(polys)
for t in [x.cell_index() for x in ly.top_cells() if x.name != top]:
    ly.delete_cell_rec(t)
print("abstract of %s: %d pin shapes kept" % (cell, kept))
ly.write(output)
