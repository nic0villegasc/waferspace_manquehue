# COMP fill (dummy active, 22/4) for the whole chip, for DCF.1a of the GF180MCU density deck (open_pdks 792ef67).
# Same set-up as the PDK fill_all.rb, but only the COMP step: the metal densities pass without fill.
# fill_comp.rb is the PDK script of open_pdks 792ef67, copied without changes.
# klayout -b -r tools/fill/fill_chip.rb -rd input=<chip.gds> -rd output=<chip_fill.gds> [-rd threads=N]
require "etc"
$stdout.sync = true
$ly = RBA::Layout::new
$ly.read($input)
$micron2dbu = RBA::CplxTrans::new($ly.dbu).inverted
$top_cell = $ly.top_cell
COMP = $ly.layer(22, 0); Poly2 = $ly.layer(30, 0)
RES_MK = $ly.layer(110, 5); IND_MK = $ly.layer(151, 5); NDMY = $ly.layer(111, 5)
Nwell = $ly.layer(21, 0); DNWELL = $ly.layer(12, 0); LVPWELL = $ly.layer(204, 0); Dualgate = $ly.layer(55, 0)
Pad = $ly.layer(37, 0)
COMP_Dummy = $ly.layer(22, 4)
$chip = $top_cell.dbbox
$threads = ($threads || Etc.nprocessors).to_i
$fill_cell_comp = $ly.create_cell("COMP_FILL")
class TilingOperator < RBA::TileOutputReceiver
  def initialize(ly, fill_cell, *fill_args)
    @ly = ly; @fill_cell = fill_cell; @fill_args = fill_args
  end
  def put(ix, iy, tile, obj, dbu, clip)
    @fill_cell.fill_region(obj, *@fill_args)
  end
end
puts "COMP fill of #{$top_cell.name}, #{$threads} threads"
load File.join(File.dirname(__FILE__), "fill_comp.rb")
# placed after the fill: the tiling processor reads the top cell while it runs
$top_cell.insert(RBA::CellInstArray::new($fill_cell_comp.cell_index, RBA::Trans::new(0, 0)))
n = 0
$fill_cell_comp.each_inst { n += 1 }
puts "COMP fill: #{n} instances of COMP_fill_cell"
$ly.write($output)
