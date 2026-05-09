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
			var delta := matrix_delta * weight
			delta *= float(stat_def.get("magnitude_factor", 1.0))
			delta *= _get_override_multiplier(overrides, avatar_id, tag, stat_id)
			if not is_zero_approx(delta):
				deltas[stat_id] = float(deltas.get(stat_id, 0.0)) + delta
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
