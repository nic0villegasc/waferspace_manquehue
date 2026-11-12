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
# Metal2 routes added to a layout (chip coordinates, after the shift): (layout, x0, y0, x1, y1).
# DB_VCO_wrapper leaves V_FB and V_REF (VCONT of the two VCOs) open at the east pads 93 and 92 (asig_5p0):
# V_FB stops 31 um before its pad at y 4260.7, V_REF ends at x 1518.6, y 4484. 5 um wide like its own wires,
# 0.5 um into the pad.
ROUTES = [("DB_VCO_wrapper", 1523.59, 4255.66, 1560.5, 4265.66),     # V_FB: across to pad 93
          ("DB_VCO_wrapper", 1513.59, 4152.0, 1518.59, 4489.38),     # V_REF: down from its end
          ("DB_VCO_wrapper", 1513.59, 4152.0, 1560.5, 4162.0)]       # V_REF: across to pad 92
# V_FB reaches the top of its own Metal2 wire (x 1523.59-1528.59, y 4260.7-4589.4) on Metal3, ending at x 1523.585
# with no via. Its Metal3 end goes over the wire top and a via2 array (0.26 um, space 0.36: V2.2b for arrays
# of 4 x 4 or more) joins them.
ROUTES_M3 = [("DB_VCO_wrapper", 1518.0, 4584.39, 1528.59, 4589.39)]
VIA2 = [("DB_VCO_wrapper", 1523.85, 4584.65, 1528.33, 4589.13)]
# Metal1 in the bottom-left corner of the first guard-ring opening of every p_mirror (VCO stages, 14 placements),
# in p_mirror coordinates. The p_inv plate next to it ends 0.1 um before the opening edge, and KLayout 0.30.12 with
# Ruby 3.4 (the precheck flake, the wafer.space platform) gives a false M1.2b space of 0.1 um at that corner. The box
# joins only the guard ring, its strip and the via_dev Metal1 that already touch: one net, no new connection.
M1_CORNER = [("p_mirror", 26.08, 0.7, 26.18, 1.21)]
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
    if globals().get("clip", "0") != "0":
        tgt.flatten(-1, True)          # only the clip needs the layout flat; else the hierarchy stays (LVS)
    before = pya.Region(tgt.shapes(m2))
    dx, dy = SHIFT.get(w, (0.0, 0.0))
    after = before if globals().get("clip", "0") == "0" else before - pads.moved(-int(round(dx / chip.dbu)), -int(round(dy / chip.dbu)))
    tgt.shapes(m2).clear()
    tgt.shapes(m2).insert(after)
    dx, dy = SHIFT.get(w, (0.0, 0.0))
    for (rw, x0, y0, x1, y1) in ROUTES:
        if rw == w:
            tgt.shapes(m2).insert(pya.DBox(x0 - dx, y0 - dy, x1 - dx, y1 - dy))
            print("INFO: %s Metal2 route (%.2f,%.2f)-(%.2f,%.2f)" % (w, x0, y0, x1, y1))
    for (rw, x0, y0, x1, y1) in ROUTES_M3:
        if rw == w:
            tgt.shapes(chip.layer(42, 0)).insert(pya.DBox(x0 - dx, y0 - dy, x1 - dx, y1 - dy))
    for (rw, x0, y0, x1, y1) in VIA2:
        if rw != w:
            continue
        n = 0
        y = y0
        while y + 0.26 <= y1 + 1e-6:
            x = x0
            while x + 0.26 <= x1 + 1e-6:
                tgt.shapes(chip.layer(38, 0)).insert(pya.DBox(x - dx, y - dy, x + 0.26 - dx, y + 0.26 - dy))
                x += 0.62; n += 1
            y += 0.62
        print("INFO: %s via2 array of %d at (%.2f,%.2f)" % (w, n, x0, y0))
    for (cn, x0, y0, x1, y1) in M1_CORNER:
        cells = [c.cell_index() for c in chip.each_cell() if c.name in (cn, "%s__%s" % (w, cn))]
        it = tgt.begin_instances_rec(); n = 0
        while not it.at_end():
            if it.inst_cell().cell_index() in cells:
                tgt.shapes(chip.layer(34, 0)).insert((it.dtrans() * it.inst_dtrans()) * pya.DBox(x0, y0, x1, y1)); n += 1
            it.next()
        if n:
            print("INFO: %s Metal1 corner box in %d %s" % (w, n, cn))
    top.insert(pya.DCellInstArray(tgt.cell_index(), pya.DTrans(pya.DVector(dx, dy))))
    print("INFO: %s Metal2 cut at %d pad cells: %.2f um2 removed" % (w, pads.count(), (before.area() - after.area()) * 1e-6))
    print("INFO: %s at %s, %d zero-area shapes dropped" % (w, tgt.dbbox(), zero))
chip.write(out)
print("INFO: wrote %s" % out)
