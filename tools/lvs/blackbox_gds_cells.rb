# Strip front-end-of-line (device-forming: diffusion/poly/well/implant/
# contact) layers from GDS cells, leaving metal/via routing and all text
# labels untouched. Used to turn a hard macro's real, full GDS view into an
# LVS-appropriate black box: KLayout's hierarchical device extraction finds
# no transistor-forming geometry inside the macro anymore (so it isn't
# extracted as thousands of individual devices), while its boundary pins
# stay fully present and connectable (same metal shapes + labels as before)
# so parent-level connectivity and pin matching are unaffected.
#
# Applies recursively to every cell in the input layout (a macro's internal
# hierarchy -- bitcell arrays, sense amps, etc. -- is typically built from
# repeated sub-cells, so stripping only the top cell would miss devices
# defined in those sub-cells).
#
# Usage:
#   klayout -b -r blackbox_gds_cells.rb \
#     -rd input=<in.gds> -rd output=<out.gds> \
#     [-rd cells=<name1,name2,...>] \
#     [-rd keep_layers="34/0,35/0,36/0,38/0,42/0,40/0,46/0,41/0,81/0,82/0,53/0,37/0"]
#
# keep_layers defaults to gf180mcu.lvs's own metal1..metaltop / via1..via5 /
# pad layer/datatype pairs (see the polygons(...) definitions near the top
# of that file) -- i.e. everything BEOL. Any layer not listed has its
# non-text shapes (boxes/polygons/paths) erased; text objects (pin labels)
# are always preserved regardless of layer.
#
# cells restricts stripping to the named cell(s) plus everything in their
# sub-hierarchy (called_cells) -- everything else in the layout is left
# completely untouched. Use this to black-box one macro's instance(s)
# inside an otherwise-real, already-merged full-chip GDS. Omit it (the
# default) to strip every cell in the file, for processing an isolated
# single-macro GDS view on its own.

def fail_with(msg)
  STDERR.puts "ERROR: #{msg}"
  exit 1
end

fail_with("missing -rd input=<path>") unless $input
fail_with("missing -rd output=<path>") unless $output
fail_with("input GDS not found: #{$input}") unless File.exist?($input)

keep_spec = $keep_layers || "34/0,35/0,36/0,38/0,42/0,40/0,46/0,41/0,81/0,82/0,53/0,37/0"
keep_pairs = keep_spec.split(",").map { |p| p.split("/").map(&:to_i) }

layout = RBA::Layout.new
layout.read($input)

keep_layer_indexes = keep_pairs.map { |l, d| layout.layer(l, d) }

target_cells =
  if $cells
    names = $cells.split(",")
    seeds = names.map do |n|
      idx = layout.cell_by_name(n) rescue nil
      STDERR.puts "WARNING: cell not present in #{$input}, skipping: #{n}" unless idx
      idx ? layout.cell(idx) : nil
    end.compact
    seeds + seeds.flat_map { |c| c.called_cells.map { |ci| layout.cell(ci) } }
  else
    layout.each_cell.to_a
  end.uniq

stripped_shapes = 0
target_cells.each do |cell|
  layout.layer_indexes.each do |li|
    next if keep_layer_indexes.include?(li)
    shapes = cell.shapes(li)
    to_erase = []
    shapes.each { |s| to_erase << s unless s.is_text? }
    to_erase.each { |s| shapes.erase(s) }
    stripped_shapes += to_erase.size
  end
end

layout.write($output)
puts "Stripped #{stripped_shapes} FEOL shapes across #{target_cells.size} target cell(s) " \
     "(of #{layout.cells} total in the file)."
puts "Kept layers: #{keep_pairs.map { |l, d| "#{l}/#{d}" }.join(", ")}"
puts "Wrote black-boxed GDS: #{$output}"
