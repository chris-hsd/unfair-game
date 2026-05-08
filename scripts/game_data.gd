extends Node

signal stats_changed

const SCHEMA_PATH := "res://data/stats_schema.csv"
const BASELINES_PATH := "res://data/avatar_baselines.csv"
const MATRIX_PATH := "res://data/tag_stat_matrix.csv"
const OVERRIDES_PATH := "res://data/avatar_overrides.csv"

var schema: Array = []
var stats: Dictionary = {}
var overrides: Array = []
var matrix: Dictionary = {}

var _schema_by_id: Dictionary = {}
var _baselines: Dictionary = {}
var _current_avatar_id: String = "default"

func _ready() -> void:
	_load_schema()
	_load_baselines()
	_load_matrix()
	_load_overrides()
	set_avatar("default")

func set_avatar(avatar_id: String) -> void:
	if not _baselines.has(avatar_id):
		avatar_id = "default"
	_current_avatar_id = avatar_id
	stats = _baselines[avatar_id].duplicate()
	stats_changed.emit()

func get_current_avatar_id() -> String:
	return _current_avatar_id

func get_stat_label(stat_id: String) -> String:
	var stat_def := get_stat_def(stat_id)
	return String(stat_def.get("name_de", stat_id))

func get_stat_def(stat_id: String) -> Dictionary:
	return _schema_by_id.get(stat_id, {})

func get_stat_value(stat_id: String) -> float:
	return float(stats.get(stat_id, 0.0))

func get_highest_label(stat_ids: Array[String]) -> String:
	var best_id := ""
	var best_value := -INF
	for stat_id in stat_ids:
		var value := get_stat_value(stat_id)
		if best_id == "" or value > best_value:
			best_id = stat_id
			best_value = value
	return get_stat_label(best_id) if best_id != "" else "-"

func apply_tag(tag: String) -> void:
	if not matrix.has(tag):
		push_warning("Unknown action tag: %s" % tag)
		return
	for stat_id in matrix[tag]:
		var delta := float(matrix[tag][stat_id])
		if is_zero_approx(delta):
			continue
		var stat_def := get_stat_def(stat_id)
		delta *= float(stat_def.get("magnitude_factor", 1.0))
		delta *= _get_override_multiplier(_current_avatar_id, tag, stat_id)
		var min_value := float(stat_def.get("scale_min", 1.0))
		var max_value := float(stat_def.get("scale_max", 10.0))
		stats[stat_id] = clamp(get_stat_value(stat_id) + delta, min_value, max_value)
	stats_changed.emit()

func _load_schema() -> void:
	var rows := _read_csv_dicts(SCHEMA_PATH)
	schema.clear()
	_schema_by_id.clear()
	for row in rows:
		var stat_id := String(row.get("stat_id", ""))
		if stat_id == "":
			continue
		var stat_def := {
			"stat_id": stat_id,
			"corner": String(row.get("corner", "")),
			"name_de": String(row.get("name_de", stat_id)),
			"scale_min": float(row.get("scale_min", 1.0)),
			"scale_max": float(row.get("scale_max", 10.0)),
			"magnitude_factor": float(row.get("magnitude_factor", 1.0)),
			"note": String(row.get("note", "")),
		}
		schema.append(stat_def)
		_schema_by_id[stat_id] = stat_def

func _load_baselines() -> void:
	_baselines.clear()
	for row in _read_csv_dicts(BASELINES_PATH):
		var avatar_id := String(row.get("avatar_id", ""))
		if avatar_id == "":
			continue
		var baseline := {}
		for stat_def in schema:
			var stat_id := String(stat_def["stat_id"])
			baseline[stat_id] = float(row.get(stat_id, 0.0))
		_baselines[avatar_id] = baseline

func _load_matrix() -> void:
	matrix.clear()
	for row in _read_csv_dicts(MATRIX_PATH):
		var tag := String(row.get("tag", ""))
		if tag == "":
			continue
		var deltas := {}
		for stat_def in schema:
			var stat_id := String(stat_def["stat_id"])
			deltas[stat_id] = float(row.get(stat_id, 0.0))
		matrix[tag] = deltas

func _load_overrides() -> void:
	overrides.clear()
	for row in _read_csv_dicts(OVERRIDES_PATH):
		overrides.append({
			"avatar_id": String(row.get("avatar_id", "")),
			"tag": String(row.get("tag", "")),
			"stat_id": String(row.get("stat_id", "")),
			"multiplier": float(row.get("multiplier", 1.0)),
			"note": String(row.get("note", "")),
		})

func _get_override_multiplier(avatar_id: String, tag: String, stat_id: String) -> float:
	for row in overrides:
		if row["avatar_id"] == avatar_id and row["tag"] == tag and row["stat_id"] == stat_id:
			return float(row["multiplier"])
	return 1.0

func _read_csv_dicts(path: String) -> Array[Dictionary]:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open CSV: %s" % path)
		return []
	var headers := PackedStringArray()
	var rows: Array[Dictionary] = []
	if not file.eof_reached():
		headers = file.get_csv_line()
	while not file.eof_reached():
		var values := file.get_csv_line()
		if values.size() == 0 or (values.size() == 1 and values[0] == ""):
			continue
		var row := {}
		for i in headers.size():
			row[headers[i]] = values[i] if i < values.size() else ""
		rows.append(row)
	return rows
