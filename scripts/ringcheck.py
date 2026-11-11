#!/usr/bin/env python3
"""Check the placed pad ring of a short LibreLane run against padring.txt (make ringcheck).

usage: python3 scripts/ringcheck.py <padring.txt> <placed chip_top.def>
For every pad and breaker of the table: placed, at its table position (centre within 0.01 um), not overlapping its
neighbour. Exit code 1 on any difference.
"""
import re
import sys

ring, defp = sys.argv[1], sys.argv[2]
DIE_W, DIE_H, PAD_W, PAD_D, EDGE, BRK_W = 1936.0, 5122.0, 75.0, 350.0, 26.0, 5.0


def side_loc(n):        # as scripts/gen_chip_ring.py
    if n <= 43:
        return "WEST", 4623.5 - 100.0 * (n - 1)
    if n <= 54:
        return "SOUTH", 410.5 + 104.0 * (n - 44)
    if n <= 97:
        return "EAST", 423.5 + 100.0 * (n - 55)
    return "NORTH", 1430.0 - 100.0 * (n - 98)


def centre(side, loc, w):
    """Expected centre of a cell of width w (along the side) placed at loc."""
    along = loc + w / 2
    return {"WEST": (EDGE + PAD_D / 2, along), "EAST": (DIE_W - EDGE - PAD_D / 2, along),
            "SOUTH": (along, EDGE + PAD_D / 2), "NORTH": (along, DIE_H - EDGE - PAD_D / 2)}[side]


expect = {}
for line in open(ring):
    f = line.split()
    if f[:1] == ["pad"]:
        side, loc = side_loc(int(f[1]))
        expect["pad_" + f[2]] = (int(f[1]), side, centre(side, loc, PAD_W), PAD_W)
    elif f[:1] == ["brk"]:
        side, loc = side_loc(int(f[2]))
        bloc = loc - 15.0 if side == "WEST" else loc + 85.0
        expect[f[1]] = (int(f[2]), side, centre(side, bloc, BRK_W), BRK_W)

d = open(defp).read()
um = int(re.search(r"UNITS DISTANCE MICRONS (\d+)", d).group(1))
comp = d[d.index("\nCOMPONENTS"):d.index("\nEND COMPONENTS")]
placed = {}
for m in re.finditer(r"-\s+(\S+)\s+(\S+)[^;]*?\+\s+(?:PLACED|FIXED)\s+\(\s*(-?\d+)\s+(-?\d+)\s*\)\s+(\w+)", comp):
    placed[m.group(1)] = (m.group(2), int(m.group(3)) / um, int(m.group(4)) / um, m.group(5))

bad = []
boxes = []
for inst, (num, side, (cx, cy), w) in sorted(expect.items(), key=lambda e: e[1][0]):
    if inst not in placed:
        bad.append("%-22s (pad %d): not placed" % (inst, num))
        continue
    master, x, y, orient = placed[inst]
    # cell size along and across the side; rotated orientations swap them
    lw, lh = (w, PAD_D)
    W, H = (lh, lw) if orient in ("E", "W", "FE", "FW") else (lw, lh)
    gx, gy = x + W / 2, y + H / 2
    boxes.append((inst, x, y, x + W, y + H))
    if abs(gx - cx) > 0.01 or abs(gy - cy) > 0.01:
        bad.append("%-22s (pad %d): centre (%.2f, %.2f), table (%.2f, %.2f)" % (inst, num, gx, gy, cx, cy))
for i, a in enumerate(boxes):
    for b in boxes[i + 1:]:
        if a[1] < b[3] and b[1] < a[3] and a[2] < b[4] and b[2] < a[4]:
            bad.append("%s overlaps %s" % (a[0], b[0]))
extra = sorted(i for i, p in placed.items() if p[0].startswith("gf180mcu_fd_io__") and i.startswith(("pad_", "brk_")) and i not in expect)
for i in extra:
    bad.append("%s is placed but not in the table" % i)

print("ringcheck: %d pads and breakers in padring.txt, %d placed" % (len(expect), sum(1 for i in expect if i in placed)))
for b in bad:
    print("  " + b)
print("ringcheck: %s" % ("PASS" if not bad else "FAIL (%d)" % len(bad)))
sys.exit(1 if bad else 0)
