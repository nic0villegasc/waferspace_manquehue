# CROC macro plus the DC-DC layouts of a folder in one GDS, to look at how they meet before a chip run.
# usage: klayout -b -r scripts/overlay.py -rd croc=<croc_soc.gds> -rd dcdc=<folder> -rd out=<gds>
# CROC goes at (392, 404) (librelane/macros/macros.yaml). Layer 255/0: CROC outline. Layer 255/1: where a DC-DC
# layout reaches inside it.
import glob, os, pya
ly = pya.Layout(); ly.dbu = 0.001
top = ly.create_cell("overlay")
c = pya.Layout(); c.read(croc)
cell = ly.create_cell("croc_soc"); cell.copy_tree(c.cell("croc_soc") or c.top_cell())
top.insert(pya.DCellInstArray(cell.cell_index(), pya.DTrans(392.0, 404.0)))
box = pya.DBox(392.0, 404.0, 392.0 + 1119.6, 404.0 + 1798.32)
top.shapes(ly.layer(255, 0)).insert(box)
for f in sorted(glob.glob(dcdc + "/*.gds")):
    w = pya.Layout(); w.read(f)
    name = os.path.splitext(os.path.basename(f))[0]
    t = ly.create_cell(name); t.copy_tree(w.cell(name))
    top.insert(pya.DCellInstArray(t.cell_index(), pya.DTrans()))
    shared = t.dbbox() & box
    if not shared.empty():
        top.shapes(ly.layer(255, 1)).insert(shared)
        print("%s reaches into CROC: %s" % (name, shared))
ly.write(out); print("wrote", out)
