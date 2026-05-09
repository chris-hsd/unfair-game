extends RefCounted
class_name EffectEngine

static func compute_deltas(
	option_tags: Dictionary,
	avatar_id: String,
	schema: Array,
	matrix: Dictionary,
	overrides: Array,
	current_stats: Dictionary = {}
) -> Dictionary:
	var schema_by_id := _build_schema_by_id(schema)
	var deltas := {}
	var debug_rows_by_stat := {}
	for tag_key in option_tags.keys():
		var tag := String(tag_key)
		var weight := float(option_tags[tag_key])
		if is_zero_approx(weight):
			continue
		if not matrix.has(tag):
			push_warning("Unknown option tag: %s" % tag)
			continue
		var tag_row = matrix[tag]
		if not (tag_row is Dictionary):
			push_warning("Invalid matrix row for tag: %s" % tag)
			continue
		for stat_key in tag_row.keys():
			var stat_id := String(stat_key)
			if not schema_by_id.has(stat_id):
				push_warning("Matrix references unknown stat: %s" % stat_id)
				continue
			var matrix_delta := float(tag_row[stat_key])
			if is_zero_approx(matrix_delta):
				continue
			var stat_def: Dictionary = schema_by_id[stat_id]
			var raw_delta := matrix_delta * weight
			var magnitude_factor := float(stat_def.get("magnitude_factor", 1.0))
			var override_factor := _get_override_multiplier(overrides, avatar_id, tag, stat_id)
			var delta := raw_delta * override_factor * magnitude_factor
			if not is_zero_approx(delta):
				deltas[stat_id] = float(deltas.get(stat_id, 0.0)) + delta
				if not debug_rows_by_stat.has(stat_id):
					debug_rows_by_stat[stat_id] = []
				debug_rows_by_stat[stat_id].append({
					"tag": tag,
					"weight": weight,
					"matrix_delta": matrix_delta,
					"raw_delta": raw_delta,
					"override_factor": override_factor,
					"magnitude_factor": magnitude_factor,
					"final_delta": delta,
				})
	_print_debug_log(avatar_id, current_stats, schema_by_id, debug_rows_by_stat, deltas)
	return deltas

static func compute_deltas_for_single_tag(
	tag: String,
	weight: float,
	avatar_id: String,
	schema: Array,
	matrix: Dictionary,
	overrides: Array,
	current_stats: Dictionary = {}
) -> Dictionary:
	return compute_deltas({tag: weight}, avatar_id, schema, matrix, overrides, current_stats)

static func _build_schema_by_id(schema: Array) -> Dictionary:
	var schema_by_id := {}
	for stat_def in schema:
		if stat_def is Dictionary:
			var stat_id := String(stat_def.get("stat_id", ""))
			if stat_id != "":
				schema_by_id[stat_id] = stat_def
	return schema_by_id

static func _get_override_multiplier(overrides: Array, avatar_id: String, tag: String, stat_id: String) -> float:
	for row in overrides:
		if not (row is Dictionary):
			continue
		if row.get("avatar_id", "") == avatar_id and row.get("tag", "") == tag and row.get("stat_id", "") == stat_id:
			return float(row.get("multiplier", 1.0))
	return 1.0

static func _print_debug_log(
	avatar_id: String,
	current_stats: Dictionary,
	schema_by_id: Dictionary,
	debug_rows_by_stat: Dictionary,
	deltas: Dictionary
) -> void:
	print("[EffectEngine] Auswahl bestaetigt, avatar_id=%s" % avatar_id)
	if deltas.is_empty():
		print("[EffectEngine] Keine Stat-Aenderungen.")
		return

	var sorted_stat_ids := deltas.keys()
	sorted_stat_ids.sort()
	for stat_id in sorted_stat_ids:
		var stat_def: Dictionary = schema_by_id.get(stat_id, {})
		var stat_name := String(stat_def.get("name_de", stat_id))
		var old_value := float(current_stats.get(stat_id, 0.0))
		var total_delta := float(deltas[stat_id])
		var new_value := old_value + total_delta
		print("[EffectEngine] %s (%s): alter Wert=%s" % [stat_id, stat_name, _fmt_float(old_value)])
		for row in debug_rows_by_stat.get(stat_id, []):
			print("  Tag=%s | Matrix-Roh-Delta=%s | Gewicht=%s | Roh-Delta=%s | Override-Faktor=%s | magnitude_factor=%s | finaler Delta=%s" % [
				String(row.get("tag", "")),
				_fmt_float(float(row.get("matrix_delta", 0.0))),
				_fmt_float(float(row.get("weight", 0.0))),
				_fmt_delta(float(row.get("raw_delta", 0.0))),
				_fmt_float(float(row.get("override_factor", 1.0))),
				_fmt_float(float(row.get("magnitude_factor", 1.0))),
				_fmt_delta(float(row.get("final_delta", 0.0))),
			])
		print("  Summe Delta=%s | neuer Wert=%s" % [_fmt_delta(total_delta), _fmt_float(new_value)])

static func _fmt_float(value: float) -> String:
	return "%.3f" % value

static func _fmt_delta(value: float) -> String:
	if value > 0.0:
		return "+%s" % _fmt_float(value)
	return _fmt_float(value)
