"""Layer properties for make view: the chip colours of gf180mcu_render.lyp (layout 1) plus the pad labels (layout 2)."""
import sys
render, out = sys.argv[1], sys.argv[2]
KINDS = [("CROC signal", "#2f6fdb"), ("CROC supply", "#e08a2c"), ("unused", "#8a8a96"),
         ("DC-DC signal", "#0f9488"), ("DC-DC supply", "#c98a2a"), ("breaker", "#18181b")]
entry = """ <properties>
  <frame-color>{c}</frame-color>
  <fill-color>{c}</fill-color>
  <frame-brightness>0</frame-brightness>
  <fill-brightness>0</fill-brightness>
  <dither-pattern>{dp}</dither-pattern>
  <line-style/>
  <valid>true</valid>
  <visible>true</visible>
  <transparent>false</transparent>
  <width>{w}</width>
  <marked>false</marked>
  <xfill>false</xfill>
  <animation>0</animation>
  <name>{n}</name>
  <source>{l}/{k}@2</source>
 </properties>
"""
add = "".join(entry.format(c=c, dp="I0", w=1, n="label: " + n, l=201, k=k) +
              entry.format(c=c, dp="I1", w=2, n="pad: " + n, l=200, k=k) for k, (n, c) in enumerate(KINDS))
s = open(render).read()
i = s.rindex("</layer-properties>")
open(out, "w").write(s[:i] + add + s[i:])
print("wrote", out)
