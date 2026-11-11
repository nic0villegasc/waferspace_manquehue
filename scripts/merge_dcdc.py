# Copy the DC-DC layouts into the chip GDS, at the place where they are drawn (make merge).
# usage: klayout -b -r scripts/merge_dcdc.py -rd input=<chip_top.gds> -rd output=<gds> [-rd gds_dir=macros/dcdc_v0]
# Every <name>.gds in gds_dir goes in. Its top cell must be named <name> and drawn in chip coordinates.
# They stay out of LibreLane because they reach into the pad area, which OpenROAD does not accept for a macro.
# Shapes with zero area are dropped (the wafer.space precheck rejects them), and a subcell whose name the chip
# already has gets the layout name as a prefix.
import glob
import os
import pya

inp = globals()["input"]
out = globals()["output"]
gds_dir = globals().get("gds_dir", "macros/dcdc_v0")
WRAPPERS = sorted(os.path.splitext(os.path.basename(f))[0] for f in glob.glob("%s/*.gds" % gds_dir))
if not WRAPPERS:
    raise SystemExit("ERROR: no GDS in %s" % gds_dir)

chip = pya.Layout()
chip.read(inp)
if abs(chip.dbu - 0.001) > 1e-9:
    raise SystemExit("ERROR: chip dbu %g is not 1 nm" % chip.dbu)
chip.dbu = 0.001
top = chip.top_cell()
for w in WRAPPERS:
    ly = pya.Layout()
    ly.read("%s/%s.gds" % (gds_dir, w))
    zero = 0
    for ci in ly.each_cell():
        for li in ly.layer_indexes():
            dead = [sh for sh in ci.shapes(li).each() if (sh.is_polygon() or sh.is_box() or sh.is_path()) and sh.polygon.area() == 0]
            for sh in dead:
                ci.shapes(li).erase(sh)
            zero += len(dead)
        if ci.name != w and chip.cell(ci.name) is not None:
            ci.name = "%s__%s" % (w, ci.name)
    if chip.cell(w) is not None:
        raise SystemExit("ERROR: the chip already has a cell %s" % w)
    tgt = chip.create_cell(w)
    tgt.copy_tree(ly.cell(w))
    top.insert(pya.DCellInstArray(tgt.cell_index(), pya.DTrans()))
    print("INFO: %s at %s, %d zero-area shapes dropped" % (w, tgt.dbbox(), zero))
chip.write(out)
print("INFO: wrote %s" % out)
