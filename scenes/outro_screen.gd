extends Control

const DATA_PATH := "res://stories/gameplay_experiences.json"
const ROW_SCENE := preload("res://scenes/profile_row.tscn")
const ICON_PATHS := {
	"anpassung": preload("res://assets/icons/pfad_anpassung.png"),
	"beziehung": preload("res://assets/icons/pfad_beziehung.png"),
	"wirkung": preload("res://assets/icons/pfad_wirkung.png"),
	"selbstbehauptung": preload("res://assets/icons/pfad_selbstbehauptung.png"),
}

var experiences: Array = []
var _rows_by_id: Dictionary = {}

@onready var profile_table: VBoxContainer = $Content/ProfileTable

func _ready() -> void:
	_load_experiences()
	_build_table()

func set_percentages(values: Dictionary) -> void:
	for path_key in values.keys():
		var path_id := String(path_key)
		if _rows_by_id.has(path_id):
			_rows_by_id[path_id].set_percent(int(values[path_key]))

func _load_experiences() -> void:
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not load %s" % DATA_PATH)
		return
	var json_text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(json_text)
	if parsed == null or not (parsed is Dictionary) or not parsed.has("experiences"):
		push_error("Invalid JSON structure in %s" % DATA_PATH)
		return
	var raw_experiences = parsed["experiences"]
	experiences = raw_experiences if raw_experiences is Array else []

func _build_table() -> void:
	_rows_by_id.clear()
	for child in profile_table.get_children():
		if child.name != "HeaderRow":
			child.queue_free()
	for entry in experiences:
		if not (entry is Dictionary):
			continue
		var path_id := String(entry.get("id", ""))
		var row = ROW_SCENE.instantiate()
		profile_table.add_child(row)
		row.populate(entry, ICON_PATHS.get(path_id, null))
		_rows_by_id[path_id] = row
