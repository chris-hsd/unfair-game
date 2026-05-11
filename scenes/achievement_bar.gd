extends Control
class_name AchievementBar

const PATHS: Array[Dictionary] = [
	{
		"id": "anpassung",
		"label": "Anpassung",
		"texture": preload("res://assets/icons/pfad_anpassung.png"),
	},
	{
		"id": "beziehung",
		"label": "Beziehung",
		"texture": preload("res://assets/icons/pfad_beziehung.png"),
	},
	{
		"id": "wirkung",
		"label": "Wirkung",
		"texture": preload("res://assets/icons/pfad_wirkung.png"),
	},
	{
		"id": "selbstbehauptung",
		"label": "Haltung",
		"texture": preload("res://assets/icons/pfad_selbstbehauptung.png"),
	},
]

const SLOT_WIDTH := 170.0
const ICON_SIZE := 48.0
const ICON_GAP := 6
const SLOT_GAP := 28
const LOCKED_ALPHA := 0.35
const LABEL_COLOR := Color(0.058824, 0.298039, 0.458824, 1.0)

var _slots: Dictionary = {}
var _unlocked: Dictionary = {}
var _locked_material: ShaderMaterial
var _debug_index := 0
var _label_font_size := 18

func _ready() -> void:
	_create_locked_material()
	_build_bar()
	for path in PATHS:
		set_path_unlocked(String(path["id"]), true)

func set_path_unlocked(path_id: String, is_unlocked: bool) -> void:
	if not _slots.has(path_id):
		push_warning("Unknown achievement path: %s" % path_id)
		return
	_unlocked[path_id] = is_unlocked
	var slot: Dictionary = _slots[path_id]
	var label: Label = slot["label"]
	var icon: TextureRect = slot["icon"]
	label.modulate = Color.WHITE if is_unlocked else Color(1.0, 1.0, 1.0, LOCKED_ALPHA)
	icon.modulate = Color.WHITE if is_unlocked else Color(1.0, 1.0, 1.0, LOCKED_ALPHA)
	icon.material = null if is_unlocked else _locked_material

func set_label_font_size_from_story_font_size(story_font_size: int) -> void:
	_label_font_size = maxi(1, int(round(float(story_font_size) * 0.8)))
	for path_id in _slots.keys():
		var slot: Dictionary = _slots[path_id]
		var label: Label = slot["label"]
		label.add_theme_font_size_override("font_size", _label_font_size)

func toggle_path(path_id: String) -> void:
	if not _slots.has(path_id):
		push_warning("Unknown achievement path: %s" % path_id)
		return
	set_path_unlocked(path_id, not bool(_unlocked.get(path_id, false)))

func debug_toggle_next_path() -> void:
	var path_id := String(PATHS[_debug_index]["id"])
	toggle_path(path_id)
	_debug_index = wrapi(_debug_index + 1, 0, PATHS.size())

func _create_locked_material() -> void:
	var shader := Shader.new()
	shader.code = "
		shader_type canvas_item;

		void fragment() {
			vec4 source = texture(TEXTURE, UV) * COLOR;
			float gray = dot(source.rgb, vec3(0.299, 0.587, 0.114));
			COLOR = vec4(vec3(gray), source.a);
		}
	"
	_locked_material = ShaderMaterial.new()
	_locked_material.shader = shader

func _build_bar() -> void:
	var row := HBoxContainer.new()
	row.name = "PathRow"
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", SLOT_GAP)
	add_child(row)

	for path in PATHS:
		var slot := VBoxContainer.new()
		slot.name = String(path["id"]).capitalize()
		slot.custom_minimum_size = Vector2(SLOT_WIDTH, 0)
		slot.alignment = BoxContainer.ALIGNMENT_CENTER
		slot.add_theme_constant_override("separation", ICON_GAP)
		row.add_child(slot)

		var label := Label.new()
		label.text = String(path["label"])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", _label_font_size)
		label.add_theme_color_override("font_color", LABEL_COLOR)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.add_child(label)

		var icon := TextureRect.new()
		icon.texture = path["texture"]
		icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		slot.add_child(icon)

		_slots[String(path["id"])] = {
			"label": label,
			"icon": icon,
		}
