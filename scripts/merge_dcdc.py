# Copy the DC-DC layouts into the chip GDS, at the place where they are drawn (make merge).
# usage: klayout -b -r scripts/merge_dcdc.py -rd input=<chip_top.gds> -rd output=<gds> [-rd gds_dir=macros/dcdc_v0]
# Every <name>.gds in gds_dir goes in. Its top cell must be named <name> and drawn in chip coordinates.
# They stay out of LibreLane because they reach into the pad area, which OpenROAD does not accept for a macro.
# Shapes with zero area are dropped (the wafer.space precheck rejects them), and a subcell whose name the chip
# already has gets the layout name as a prefix.
# DB_VCO_wrapper was drawn against a pad ring 0.5 um lower than this one: its pad wires miss the pad pins (CS, SL,
# A of the west bi_24t pads) by 0.5 um in y, which gave 184 Metal2 errors (M2.2a, M2.1) in the precheck. The
# Makefile shifts it by 0.5 um up (-rd shift=); its Metal2 still touches Channels_wrapper at the same 48 shapes.
# -rd clip=1 cuts the Metal2 of the layouts back to the outside of the pad cells (not used: it removes the
# intended overlap of the wires on the pad pins).
import glob
import os
import pya

inp = globals()["input"]
out = globals()["output"]
gds_dir = globals().get("gds_dir", "macros/dcdc_v0")
# Optional shift per layout in um: -rd shift="DB_VCO_wrapper:0,0.5;Other:x,y"
SHIFT = {}
for item in filter(None, globals().get("shift", "").split(";")):
    name, xy = item.split(":")
    SHIFT[name] = tuple(float(v) for v in xy.split(","))
WRAPPERS = sorted(os.path.splitext(os.path.basename(f))[0] for f in glob.glob("%s/*.gds" % gds_dir))
if not WRAPPERS:
    raise SystemExit("ERROR: no GDS in %s" % gds_dir)

chip = pya.Layout()
chip.read(inp)
if abs(chip.dbu - 0.001) > 1e-9:
    raise SystemExit("ERROR: chip dbu %g is not 1 nm" % chip.dbu)
chip.dbu = 0.001
top = chip.top_cell()
PAD_PREFIXES = ("gf180mcu_fd_io__", "gf180mcu_ws_io__", "pad_")
pads = pya.Region()
for inst in top.each_inst():
    if inst.cell.name.startswith(PAD_PREFIXES):
        pads.insert(inst.bbox())
pads.merge()
m2 = chip.layer(36, 0)
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
    tgt.flatten(-1, True)
    before = pya.Region(tgt.shapes(m2))
    dx, dy = SHIFT.get(w, (0.0, 0.0))
    after = before if globals().get("clip", "0") == "0" else before - pads.moved(-int(round(dx / chip.dbu)), -int(round(dy / chip.dbu)))
    tgt.shapes(m2).clear()
    tgt.shapes(m2).insert(after)
    dx, dy = SHIFT.get(w, (0.0, 0.0))
    top.insert(pya.DCellInstArray(tgt.cell_index(), pya.DTrans(pya.DVector(dx, dy))))
    print("INFO: %s Metal2 cut at %d pad cells: %.2f um2 removed" % (w, pads.count(), (before.area() - after.area()) * 1e-6))
    print("INFO: %s at %s, %d zero-area shapes dropped" % (w, tgt.dbbox(), zero))
chip.write(out)
print("INFO: wrote %s" % out)
