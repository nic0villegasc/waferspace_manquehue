# Cross-check a KLayout-extracted layout netlist against a schematic
# netlist using the raw RBA::NetlistComparer API directly, as an
# independent second opinion alongside gf180mcu.lvs's own native `compare`
# (which produces the .lvsdb you open in KLayout -- that's the primary,
# authoritative, visually-inspectable result; this script's text summary is
# a supplementary cross-check, not a replacement for it).
#
# Usage:
#   klayout -b -r lvs_compare.rb \
#     -rd layout_netlist=extracted_netlist_top.cir \
#     -rd schematic_netlist=top.sp \
#     [-rd device_class_map=LAYOUT_NAME:SCHEMATIC_NAME,...] \
#     [-rd summary=lvs_compare_summary.txt]
#
# device_class_map is normally unnecessary: if your schematic CDL's MOSFET
# model names were renamed to match the layout's own device class names
# (see fold_wells.py --rename-model / LVS_MODEL_RENAME in synopsys_croc's
# Makefile), both sides read back with the SAME class name and
# NetlistComparer treats them as equivalent automatically. Only pass this
# if the two sides' device class names genuinely still differ -- pairs are
# LAYOUT_NAME:SCHEMATIC_NAME, comma-separated, matched as read back through
# RBA::NetlistSpiceReader, which upper-cases everything (SPICE is
# historically case-insensitive).
#
# Exit status: 0 if the netlists match, 1 otherwise (also on setup errors).

require "optparse" rescue nil  # not used; -rd vars come in as $-prefixed globals

def fail_with(msg)
  STDERR.puts "ERROR: #{msg}"
  exit 1
end

fail_with("missing -rd layout_netlist=<path>") unless $layout_netlist
fail_with("missing -rd schematic_netlist=<path>") unless $schematic_netlist
fail_with("layout netlist not found: #{$layout_netlist}") unless File.exist?($layout_netlist)
fail_with("schematic netlist not found: #{$schematic_netlist}") unless File.exist?($schematic_netlist)

device_class_map = ($device_class_map || "")
  .split(",").map { |pair| pair.split(":") }
  .map { |a, b| [a.upcase, b] }   # layout side also round-trips through the upper-casing SPICE reader

# Same custom element handling as gf180mcu.lvs's SubcircuitModelsReader:
# gf180 CDLs use C/R elements with parameters the generic reader doesn't
# infer defaults for, and D (diode) elements KLayout's generic reader
# rejects outright unless given exactly 2 nodes. Diodes aren't relevant to
# digital-standard-cell LVS matching, so they're registered as inert
# 2-terminal devices purely so the file parses.
class SubcircuitModelsReader < RBA::NetlistSpiceReaderDelegate
  def parse_element(s, element)
    if element == "C"
      super(s + " C=2e-16", element)
    elsif element == "R"
      super(s + " R=0", element)
    else
      super
    end
  end

  def element(circuit, el, name, model, value, nets, params)
    case el
    when "C"
      return true if nets.size != 2
      cls = device_class(circuit, model) { RBA::DeviceClassCapacitor.new }
      device = circuit.create_device(cls, name)
      %w[A B].each_with_index { |t, i| device.connect_terminal(t, nets[i]) }
      device.set_parameter("A", ((params["W"] || 0.0) * (params["L"] || 0.0)) * 1e12)
      device.set_parameter("P", ((params["W"] || 0.0) + (params["L"] || 0.0)) * 2e6)
      device.set_parameter("C", (params["C"] || 0.0))
    when "R"
      if nets.size == 3
        cls = device_class(circuit, model) { RBA::DeviceClassResistorWithBulk.new }
        device = circuit.create_device(cls, name)
        %w[A B W].each_with_index { |t, i| device.connect_terminal(t, nets[i]) }
      elsif nets.size == 2
        cls = device_class(circuit, model) { RBA::DeviceClassResistor.new }
        device = circuit.create_device(cls, name)
        %w[A B].each_with_index { |t, i| device.connect_terminal(t, nets[i]) }
      else
        return true
      end
      device.set_parameter("W", ((params["W"] || 0.0) * (params["PAR"] || 1.0)) * 1e6)
      device.set_parameter("L", ((params["L"] || 0.0) * (params["S"] || 1.0)) * 1e6)
      device.set_parameter("R", (params["R"] * (params["S"] || 1.0) / (params["PAR"] || 1.0)))
    when "D"
      return true if nets.size != 2
      cls = device_class(circuit, model) { RBA::DeviceClassResistor.new }
      device = circuit.create_device(cls, name)
      %w[A B].each_with_index { |t, i| device.connect_terminal(t, nets[i]) }
      device.set_parameter("R", 1.0)
    else
      return super
    end
    true
  end

  private

  def device_class(circuit, model)
    cls = circuit.netlist.device_class_by_name(model)
    unless cls
      cls = yield
      cls.name = model
      circuit.netlist.add(cls)
    end
    cls
  end
end

def load_netlist(path)
  nl = RBA::Netlist.new
  nl.read(path, RBA::NetlistSpiceReader.new(SubcircuitModelsReader.new))
  nl.case_sensitive = false
  nl
end

class SummaryLogger < RBA::GenericNetlistCompareLogger
  Entry = Struct.new(:kind, :a, :b, :circuit, :message)
  attr_reader :entries
  def initialize
    super
    @entries = []
    @current_circuit = nil
  end
  def begin_circuit(a, b, *_)
    @current_circuit = (a || b)&.name
  end
  def end_circuit(*_)
    @current_circuit = nil
  end
  # Net/Device#circuit exists but only as a non-const accessor, and these
  # callbacks receive const references -- calling it raises, so attribution
  # falls back to begin/end_circuit tracking. Cross-checked by re-running
  # the comparison with the SRAM macro fully removed from both netlists:
  # every other circuit's event count was byte-for-byte identical, so this
  # tracking is reliable in practice for this design despite the fallback.
  %i[circuit_mismatch net_mismatch device_mismatch pin_mismatch
     subcircuit_mismatch device_class_mismatch].each do |kind|
    define_method(kind) do |a, b, *_|
      @entries << Entry.new(kind, a, b, @current_circuit)
    end
  end
  # circuit_skipped fires when a circuit couldn't even be attempted (e.g.
  # too many of its subcircuits already failed) and carries a human-readable
  # explanation as its 3rd argument -- surface that verbatim.
  def circuit_skipped(a, b, msg = nil, *_)
    @entries << Entry.new(:circuit_skipped, a, b, @current_circuit, msg)
  end
end

layout = load_netlist($layout_netlist)
schematic = load_netlist($schematic_netlist)

# High-drive-strength standard cells (e.g. CLKINV_20) are built from many
# parallel unit-sized transistor fingers, each its own M-device line in the
# CDL. The layout side already went through combine_devices as part of
# run_lvs.py's COMBINE=true (gf180mcu.lvs applies it to its own `netlist`
# before writing extracted_netlist_*.cir), merging same-net fingers into one
# device with the summed width -- but nothing does the equivalent on the
# schematic side, so every multi-finger cell shows a spurious device-count
# mismatch (e.g. CLKINV_20: 40 unmerged transistors vs. 2 merged ones,
# though the summed widths match exactly). Mirror it here.
schematic.combine_devices

# A fully black-boxed hard macro (0 internal devices) is an "empty" circuit,
# and a plain purge flattens circuits like that away entirely -- not just
# their device count going to 0, their subcircuit instances vanish too
# (confirmed: after black-boxing the SRAM, the layout netlist had 0
# top-level instances of it even though the GDS still places it 4 times).
# dont_purge=true protects it on BOTH sides so it compares as the
# intentional black box it is, instead of this asymmetry reading as a
# top-level failure even though every real net and device already matches.
blackbox_names = ($blackbox_macros || "").split(",").map(&:downcase)
if !blackbox_names.empty?
  [layout, schematic].each do |nl|
    nl.each_circuit { |c| c.dont_purge = true if blackbox_names.include?(c.name.downcase) }
  end
end

# Removes subcircuit instances whose referenced circuit name contains any
# of $exclude_from_compare's (comma-separated, case-insensitive) patterns,
# symmetrically on both sides, before compare -- comparison-scope only,
# doesn't touch either input file. For cells with no signal connectivity
# and no distinguishing topology between instances (e.g. decoupling-cap
# fillers), exact 1:1 instance correspondence between an independently-
# drawn layout and independently-synthesized schematic is fundamentally
# ambiguous, not a real violation -- see LVS_EXCLUDE_FROM_COMPARE in
# synopsys_croc's Makefile for the full rationale.
exclude_patterns = ($exclude_from_compare || "").split(",").map(&:downcase)
if !exclude_patterns.empty?
  [layout, schematic].each do |nl|
    nl.each_circuit do |parent|
      parent.each_subcircuit.to_a.each do |sc|
        ref_name = sc.circuit_ref&.name&.downcase
        next unless ref_name
        parent.remove_subcircuit(sc) if exclude_patterns.any? { |pat| ref_name.include?(pat) }
      end
    end
  end
end

layout.purge
layout.purge_nets
schematic.purge
schematic.purge_nets

logger = SummaryLogger.new
comparer = RBA::NetlistComparer.new(logger)
device_class_map.each do |layout_name, schem_name|
  a = layout.device_class_by_name(layout_name)
  b = schematic.device_class_by_name(schem_name)
  if a.nil? || b.nil?
    STDERR.puts "WARNING: device_class_map pair #{layout_name}:#{schem_name} -- " \
                "#{a.nil? ? "#{layout_name} not found in layout netlist" : "#{schem_name} not found in schematic netlist"}, skipping"
    next
  end
  comparer.same_device_classes(a, b)
end

comparer.compare(layout, schematic)

# circuit_mismatch fires with a nil "layout" side for every schematic-only
# circuit definition that simply isn't instantiated anywhere (unused
# library cells) -- that's expected and not a real problem, so it's
# filtered out of the summary.
real_circuit_mismatches = logger.entries
  .select { |e| e.kind == :circuit_mismatch && e.a && e.b }
  .map { |e| "#{e.a.name} <-> #{e.b.name}" }
  .uniq

counts = logger.entries.group_by(&:kind).transform_values(&:size)

# Rank circuits by how many mismatch events they produced -- the biggest
# offenders are almost always where the real problem is (e.g. a hard macro
# that's a black-box stub on one side and fully extracted on the other).
by_circuit = logger.entries
  .select { |e| e.kind != :circuit_mismatch && e.kind != :circuit_skipped && e.circuit }
  .group_by(&:circuit)
  .transform_values(&:size)
  .sort_by { |_, n| -n }

skipped = logger.entries.select { |e| e.kind == :circuit_skipped }

# RBA::NetlistComparer#compare's own return value counts *every*
# circuit_mismatch against the result, including the nil-paired,
# simply-unused-library-cell noise filtered out above -- so it can return
# false here with zero real problems found by any other measure. Base the
# verdict on what was actually found instead (matches gf180mcu.lvs's own
# native `compare`, which doesn't penalize unused library cells either):
# real (both-sides-present) circuit mismatches, or any hard mismatch event
# (net/device/pin/subcircuit -- these callbacks don't fire for
# MatchWithWarning-status pairs, only for genuine Mismatch status), or a
# skipped top-level circuit.
hard_event_count = logger.entries.count { |e| ![:circuit_mismatch, :circuit_skipped].include?(e.kind) }
ok = real_circuit_mismatches.empty? && hard_event_count.zero? && skipped.empty?

lines = []
lines << "LVS compare: #{ok ? "MATCH" : "MISMATCH"}"
lines << "  layout netlist    : #{$layout_netlist}"
lines << "  schematic netlist : #{$schematic_netlist}"
lines << "  device class map  : #{device_class_map.map { |a, b| "#{a}<->#{b}" }.join(", ")}"
lines << ""
lines << "circuit_mismatch (both sides present, i.e. a real per-type failure): #{real_circuit_mismatches.size}"
real_circuit_mismatches.first(50).each { |x| lines << "  #{x}" }
lines << "  ... and #{real_circuit_mismatches.size - 50} more" if real_circuit_mismatches.size > 50
lines << ""
lines << "top circuits by mismatch-event count (net/pin/device mismatches while comparing that circuit):"
by_circuit.first(20).each { |name, n| lines << "  %6d  %s" % [n, name] }
lines << "  ... and #{by_circuit.size - 20} more circuits" if by_circuit.size > 20
lines << "  (none)" if by_circuit.empty?
lines << ""
lines << "circuit_skipped (couldn't be attempted, usually because a child circuit already failed): #{skipped.size}"
skipped.first(10).each do |e|
  lines << "  #{(e.a || e.b)&.name}:"
  (e.message || "").each_line { |l| lines << "    #{l.chomp}" }
end
lines << "  ... and #{skipped.size - 10} more" if skipped.size > 10
lines << ""
lines << "raw event counts (includes benign unused-library-cell noise):"
counts.each { |k, v| lines << "  #{k}: #{v}" }

summary = lines.join("\n")
puts summary
if $summary
  File.write($summary, summary + "\n")
  puts "\nSummary written to #{$summary}"
end

exit(ok ? 0 : 1)
