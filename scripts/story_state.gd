extends Node

signal story_changed
signal mode_changed
signal selection_changed
signal focus_changed

enum Mode { AVATAR, STORY }
enum Focus { STORY, OPTIONS }

const EffectEngineScript := preload("res://scripts/effect_engine.gd")
const STORY_PATHS: Array[String] = [
	"res://stories/01_kennenlernen.json",
	"res://stories/02_themenwahl.json",
	"res://stories/03_anna_verschwindet.json",
]

var current_story: Dictionary = {}
var current_story_index: int = 0
var selected_option_index: int = 0
var story_page_index: int = 0
var mode: int = Mode.STORY
var focus: int = Focus.OPTIONS
var is_complete: bool = false

func _ready() -> void:
	load_story(0)

func load_story(index: int) -> void:
	if index >= STORY_PATHS.size():
		current_story = {
			"scene_id": "complete",
			"scene_title": "Ende",
			"story_hook": "Die bisherigen Entscheidungen sind getroffen.",
			"options": [],
		}
		is_complete = true
	else:
		var loaded := _load_json_file(STORY_PATHS[index])
		if loaded.is_empty():
			current_story = {
				"scene_id": "load_error",
				"scene_title": "Fehler",
				"story_hook": "Diese Szene konnte nicht geladen werden: %s" % STORY_PATHS[index],
				"options": [],
			}
			is_complete = true
		else:
			current_story = loaded
			is_complete = false
	current_story_index = index
	selected_option_index = 0
	story_page_index = 0
	story_changed.emit()
	selection_changed.emit()

func advance_story() -> void:
	if not is_complete:
		load_story(current_story_index + 1)

func set_mode(next_mode: int) -> void:
	if mode == next_mode:
		return
	mode = next_mode
	mode_changed.emit()

func toggle_mode() -> void:
	set_mode(Mode.AVATAR if mode == Mode.STORY else Mode.STORY)

func toggle_focus() -> void:
	focus = Focus.STORY if focus == Focus.OPTIONS else Focus.OPTIONS
	focus_changed.emit()

func select_option(offset: int) -> void:
	var options := get_options()
	if options.is_empty():
		return
	selected_option_index = wrapi(selected_option_index + offset, 0, options.size())
	selection_changed.emit()

func next_story_page(page_count: int) -> void:
	if page_count <= 0:
		return
	story_page_index = mini(story_page_index + 1, page_count - 1)
	story_changed.emit()

func previous_story_page() -> void:
	story_page_index = maxi(story_page_index - 1, 0)
	story_changed.emit()

func get_story_hook() -> String:
	return String(current_story.get("story_hook", ""))

func get_scene_title() -> String:
	return String(current_story.get("scene_title", ""))

func get_options() -> Array:
	var raw_options = current_story.get("options", [])
	return raw_options if raw_options is Array else []

func get_selected_option() -> Dictionary:
	var options := get_options()
	if selected_option_index < 0 or selected_option_index >= options.size():
		return {}
	var option = options[selected_option_index]
	return option if option is Dictionary else {}

func apply_selected_option_effects() -> Dictionary:
	var option := get_selected_option()
	if option.is_empty():
		return {}
	var option_tags = option.get("option_tags", {})
	if not (option_tags is Dictionary):
		push_warning("Selected option has no valid option_tags")
		return {}
	var deltas: Dictionary = EffectEngineScript.compute_deltas(
		option_tags,
		GameData.get_current_avatar_id(),
		GameData.schema,
		GameData.matrix,
		GameData.overrides,
		GameData.stats
	)
	GameData.apply_deltas(deltas)
	return deltas

func _load_json_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open story JSON: %s" % path)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed == null or not (parsed is Dictionary):
		push_error("Could not parse story JSON: %s" % path)
		return {}
	return parsed
