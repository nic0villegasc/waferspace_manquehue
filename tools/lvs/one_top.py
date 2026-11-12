# Write cell `top` and its tree alone (also a cell inside another one). klayout -b -r, -rd input= output= top=
import pya
ly = pya.Layout(); ly.read(input)
c = ly.cell(top)
if c is None: raise SystemExit("ERROR: no cell %s" % top)
out = pya.Layout(); out.dbu = ly.dbu
n = out.create_cell(top)
n.copy_tree(c)
out.write(output); print("kept", top, "with", len(list(n.each_child_cell())), "child cells")
