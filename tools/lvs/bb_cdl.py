# Verilog blackbox stub (module ports and widths) -> CDL .SUBCKT with bit-blasted pins name[i].
import re, sys
t = re.sub(r"//.*", "", open(sys.argv[1]).read())
mod = re.search(r"module\s+(\w+)", t).group(1)
pins = []
for m in re.finditer(r"\b(input|output|inout)\s*(\[(\d+):(\d+)\])?\s*([\w\s,]+);", t):
    for n in [x.strip() for x in m.group(5).split(",") if x.strip()]:
        if m.group(2):
            a, b = int(m.group(3)), int(m.group(4))
            pins += ["%s[%d]" % (n, i) for i in range(a, b - 1 if a >= b else b + 1, -1 if a >= b else 1)]
        else:
            pins.append(n)
print(".SUBCKT %s %s\n.ENDS %s" % (mod, " ".join(pins), mod))
