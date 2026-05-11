extends Control

const DATA_PATH := "res://stories/gameplay_experiences.json"
const TEXT_COLOR := Color(0.976471, 0.960784, 0.921569, 1.0)
const HEADER_COLOR := Color(0.72, 0.72, 0.72, 1.0)
const BORDER_COLOR := Color(0.976471, 0.960784, 0.921569, 1.0)
const EXPERIENCE_COLUMN_WIDTH := 190.0
const PERCENT_COLUMN_WIDTH := 110.0
const ICON_SIZE := 48.0
const ICON_PATHS := {
	"anpassung": preload("res://assets/icons/pfad_anpassung.png"),
	"beziehung": preload("res://assets/icons/pfad_beziehung.png"),
	"wirkung": preload("res://assets/icons/pfad_wirkung.png"),
	"selbstbehauptung": preload("res://assets/icons/pfad_selbstbehauptung.png"),
}

var experiences: Array = []

@onready var profile_table: VBoxContainer = $Content/ProfileTable

func _ready() -> void:
	_load_experiences()
	_build_table()

func set_percentages(values: Dictionary) -> void:
	for entry in experiences:
		if not (entry is Dictionary):
			continue
		var path_id := String(entry.get("id", ""))
		if values.has(path_id):
			entry["percentage"] = int(values[path_id])
	_build_table()

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
	for child in profile_table.get_children():
		child.queue_free()
	var header_row := _create_row()
	header_row.add_child(_create_header_cell("Spielerfahrung", EXPERIENCE_COLUMN_WIDTH))
	header_row.add_child(_create_header_cell("Prozent", PERCENT_COLUMN_WIDTH))
	header_row.add_child(_create_header_cell("Interpretation", 0.0, true))
	profile_table.add_child(header_row)
	for entry in experiences:
		if entry is Dictionary:
			var row := _create_row()
			row.add_child(_create_experience_cell(entry))
			row.add_child(_create_body_cell("%d%%" % int(entry.get("percentage", 0)), PERCENT_COLUMN_WIDTH))
			row.add_child(_create_body_cell(String(entry.get("interpretation", "")), 0.0, true, true))
			profile_table.add_child(row)

func _create_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 0)
	return row

func _create_header_cell(text: String, min_width: float, should_expand := false) -> PanelContainer:
	var cell := _create_cell_panel(min_width, should_expand)
	var label := _create_cell_label(text, HEADER_COLOR)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_font_size_override("font_weight", 700)
	cell.add_child(label)
	return cell

func _create_experience_cell(entry: Dictionary) -> PanelContainer:
	var cell := _create_cell_panel(EXPERIENCE_COLUMN_WIDTH, false)
	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 8)
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cell.add_child(layout)

	var label := _create_cell_label(_short_experience_name(String(entry.get("name", ""))), TEXT_COLOR)
	label.add_theme_font_size_override("font_size", 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.add_child(label)

	var icon := TextureRect.new()
	icon.texture = ICON_PATHS.get(String(entry.get("id", "")), null)
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	layout.add_child(icon)
	return cell

func _create_body_cell(text: String, min_width: float, should_wrap := false, should_expand := false) -> PanelContainer:
	var cell := _create_cell_panel(min_width, should_expand)
	var label := _create_cell_label(text, TEXT_COLOR)
	label.add_theme_font_size_override("font_size", 20)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if should_wrap else TextServer.AUTOWRAP_OFF
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.add_child(label)
	return cell

func _create_cell_panel(min_width: float, should_expand: bool) -> PanelContainer:
	var cell := PanelContainer.new()
	cell.custom_minimum_size = Vector2(min_width, 0.0)
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL if should_expand else Control.SIZE_SHRINK_BEGIN
	cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = BORDER_COLOR
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.content_margin_left = 14.0
	style.content_margin_top = 12.0
	style.content_margin_right = 14.0
	style.content_margin_bottom = 12.0
	cell.add_theme_stylebox_override("panel", style)
	return cell

func _create_cell_label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	return label

func _short_experience_name(name: String) -> String:
	if name.begins_with("Pfad der "):
		return name.trim_prefix("Pfad der ")
	return name
