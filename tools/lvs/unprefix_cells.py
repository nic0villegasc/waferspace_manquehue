# Standard cells copied into LibreLane macros carry a 2-character prefix (HN_gf180mcu_fd_sc_...), and a second
# copy of a cell read from another GDS a $N suffix. For LVS the
# instances of such a copy point to the cell of the plain name (or the copy is renamed when there is none), so
# the layout has one circuit per standard cell, as the schematic. klayout -b -r, -rd input= output=
import pya, re
ly = pya.Layout(); ly.read(input)
pref = re.compile(r"^(?:[A-Z0-9]{2}_(gf180mcu_fd_sc_\S+?)|(gf180mcu_fd_sc_\S+?)\$\d+)$")
done = rn = 0
for c in list(ly.each_cell()):
    m = pref.match(c.name)
    if not m: continue
    base = ly.cell((m.group(1) or m.group(2)))
    if base is None:
        c.name = (m.group(1) or m.group(2)); rn += 1; continue
    for p in list(c.each_parent_inst()):
        inst = p.child_inst(); inst.cell_index = base.cell_index()
    done += 1
for c in [c.cell_index() for c in ly.each_cell() if pref.match(c.name)]:
    if ly.cell(c).parent_cells() == 0: ly.delete_cell(c)
ly.write(output); print("prefixed standard cells: %d mapped to the plain cell, %d renamed" % (done, rn))
