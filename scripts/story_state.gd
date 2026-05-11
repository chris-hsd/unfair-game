extends Node

signal story_changed
signal mode_changed
signal selection_changed
signal focus_changed

enum Mode { AVATAR, STORY }
enum Focus { STORY, OPTIONS }

const EffectEngineScript := preload("res://scripts/effect_engine.gd")
const STORY_DIRECTORY := "res://stories"

var current_story: Dictionary = {}
var current_story_index: int = 0
var selected_option_index: int = 0
var story_page_index: int = 0
var mode: int = Mode.STORY
var focus: int = Focus.OPTIONS
var is_complete: bool = false
var _last_text_resolution: Dictionary = {}
var _story_paths: Array[String] = []

func _ready() -> void:
	_story_paths = _load_story_paths()
	load_story(0)

func load_story(index: int) -> void:
	if index >= _story_paths.size():
		current_story = {
			"scene_id": "complete",
			"scene_title": "Ende",
			"story_hook": "Die bisherigen Entscheidungen sind getroffen.",
			"options": [],
		}
		is_complete = true
	else:
		var story_path := _story_paths[index]
		var loaded := _load_json_file(story_path)
		if loaded.is_empty():
			current_story = {
				"scene_id": "load_error",
				"scene_title": "Fehler",
				"story_hook": "Diese Szene konnte nicht geladen werden: %s" % story_path,
				"options": [],
			}
			is_complete = true
		else:
			current_story = loaded
			is_complete = false
	current_story_index = index
	selected_option_index = 0
	story_page_index = 0
	_log_current_option_text_variants()
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
	var variants = current_story.get("story_hook_variants", [])
	var avatar_id := GameData.get_current_avatar_id() if get_node_or_null("/root/GameData") != null else ""
	var text := resolve_text(
		String(current_story.get("story_hook", "")),
		variants if variants is Array else [],
		avatar_id
	)
	_log_text_resolution("story_hook_variant", "", _last_text_resolution)
	return text

func get_scene_title() -> String:
	return String(current_story.get("scene_title", ""))

func get_options() -> Array:
	var raw_options = current_story.get("options", [])
	return raw_options if raw_options is Array else []

func get_option_text(option: Dictionary) -> String:
	return _resolve_option_text(option, false)

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

func resolve_text(default_text: String, variants: Array, avatar_id: String) -> String:
	_last_text_resolution = {
		"matched": false,
		"index": -1,
		"reason": "keine Variante traf",
	}
	for index in range(variants.size()):
		var variant = variants[index]
		if not (variant is Dictionary):
			continue
		var match_result := _variant_matches(variant, avatar_id)
		if bool(match_result.get("matched", false)):
			_last_text_resolution = {
				"matched": true,
				"index": index,
				"reason": _join_reasons(match_result.get("reasons", [])),
			}
			return String(variant.get("text", default_text))
	return default_text

func _resolve_option_text(option: Dictionary, should_log: bool) -> String:
	var variants = option.get("option_text_variants", [])
	var avatar_id := GameData.get_current_avatar_id() if get_node_or_null("/root/GameData") != null else ""
	var text := resolve_text(
		String(option.get("option_text", "")),
		variants if variants is Array else [],
		avatar_id
	)
	if should_log:
		_log_text_resolution("option_text_variant", String(option.get("option_id", "")), _last_text_resolution)
	return text

func _log_current_option_text_variants() -> void:
	for option in get_options():
		if option is Dictionary:
			_resolve_option_text(option, true)

func _log_text_resolution(kind: String, option_id: String, result: Dictionary) -> void:
	if not bool(result.get("matched", false)):
		return
	var selected := "variant matched: %d" % int(result.get("index", -1))
	var parts: Array[String] = [
		"[StoryState]",
		kind,
		"scene_id=%s" % String(current_story.get("scene_id", "")),
	]
	if option_id != "":
		parts.append("option_id=%s" % option_id)
	parts.append("selected=%s" % selected)
	parts.append("reason=%s" % String(result.get("reason", "")))
	print(" ".join(parts))

func _variant_matches(variant: Dictionary, avatar_id: String) -> Dictionary:
	var reasons: Array[String] = []
	if variant.has("avatar_id"):
		var expected_avatar_id := String(variant.get("avatar_id", ""))
		if avatar_id != expected_avatar_id:
			return {"matched": false, "reasons": []}
		reasons.append("matched avatar_id=%s" % avatar_id)

	if variant.has("condition"):
		var condition = variant.get("condition", {})
		if not (condition is Dictionary):
			push_warning("Invalid variant condition in scene: %s" % String(current_story.get("scene_id", "")))
			return {"matched": false, "reasons": []}
		for stat_key in condition.keys():
			var stat_id := String(stat_key)
			var expression := String(condition[stat_key]).strip_edges()
			var comparison := _parse_condition_expression(expression)
			if not bool(comparison.get("valid", false)):
				push_warning("Invalid variant condition expression: %s%s" % [stat_id, expression])
				return {"matched": false, "reasons": []}
			var current_value := GameData.get_stat_internal(stat_id) if get_node_or_null("/root/GameData") != null else 0.0
			if not _compare_condition_value(current_value, String(comparison.get("operator", "")), float(comparison.get("value", 0.0))):
				return {"matched": false, "reasons": []}
			reasons.append("condition %s%s erfuellt mit %s=%s" % [
				stat_id,
				expression,
				stat_id,
				_fmt_float(current_value),
			])

	return {"matched": true, "reasons": reasons}

func _join_reasons(reasons: Array) -> String:
	var text_parts: Array[String] = []
	for reason in reasons:
		text_parts.append(String(reason))
	return "; ".join(text_parts)

func _parse_condition_expression(expression: String) -> Dictionary:
	for operator in [">=", "<=", "==", ">", "<"]:
		if expression.begins_with(operator):
			var number_text := expression.substr(operator.length()).strip_edges()
			if not number_text.is_valid_float():
				return {"valid": false}
			return {
				"valid": true,
				"operator": operator,
				"value": number_text.to_float(),
			}
	return {"valid": false}

func _compare_condition_value(current_value: float, operator: String, target_value: float) -> bool:
	match operator:
		">":
			return current_value > target_value
		"<":
			return current_value < target_value
		">=":
			return current_value >= target_value
		"<=":
			return current_value <= target_value
		"==":
			return is_equal_approx(current_value, target_value)
	return false

func _fmt_float(value: float) -> String:
	return "%.3f" % value

func _load_story_paths() -> Array[String]:
	var paths: Array[String] = []
	var directory := DirAccess.open(STORY_DIRECTORY)
	if directory == null:
		push_error("Could not open story directory: %s" % STORY_DIRECTORY)
		return paths

	directory.list_dir_begin()
	var file_name := directory.get_next()
	while file_name != "":
		if not directory.current_is_dir() and file_name.ends_with(".json") and _is_story_scene_file(file_name):
			paths.append("%s/%s" % [STORY_DIRECTORY, file_name])
		file_name = directory.get_next()
	directory.list_dir_end()
	paths.sort()
	print("[StoryState] loaded %d story files from %s" % [paths.size(), STORY_DIRECTORY])
	return paths

func _is_story_scene_file(file_name: String) -> bool:
	if file_name.length() < 3:
		return false
	return file_name.substr(0, 2).is_valid_int() and file_name.substr(2, 1) == "_"

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
