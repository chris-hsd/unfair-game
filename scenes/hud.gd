extends CanvasLayer

const PROJEKT_STATS: Array[String] = ["proj_sicht", "proj_ress", "proj_transf", "proj_stab"]
const SCHULE_STATS: Array[String] = ["sch_vert", "sch_rep", "sch_norm", "sch_unt"]
const AG_STATS: Array[String] = ["ag_anerk", "ag_bet", "ag_komm", "ag_abh"]
const AUFMERKSAMKEIT_STATS: Array[String] = ["lt_aufm_leist", "lt_aufm_sicht", "lt_aufm_foerd"]
const INTERPRETATION_STATS: Array[String] = ["lt_int_def", "lt_int_pot", "lt_int_str"]
const STORY_PAGE_CHAR_LIMIT := 260
const CORNER_TEXT_COLOR := Color(0.058824, 0.298039, 0.458824, 1.0)

@onready var projekt_grid: GridContainer = $Root/ProjektPanel/MarginContainer/ProjektLayout/Grid
@onready var schule_grid: GridContainer = $Root/SchulePanel/MarginContainer/SchuleLayout/Grid
@onready var leitung_grid: GridContainer = $Root/LeitungPanel/MarginContainer/LeitungLayout/Grid
@onready var ag_grid: GridContainer = $Root/AgPanel/MarginContainer/AgLayout/Grid
@onready var story_panel: PanelContainer = $Root/StoryPanel
@onready var story_title: Label = $Root/StoryPanel/MarginContainer/StoryLayout/Title
@onready var story_text: Label = $Root/StoryPanel/MarginContainer/StoryLayout/StoryText
@onready var story_hint: Label = $Root/StoryPanel/MarginContainer/StoryLayout/StoryHint
@onready var options_panel: PanelContainer = $Root/OptionsPanel
@onready var options_grid: GridContainer = $Root/OptionsPanel/MarginContainer/OptionsLayout/OptionsGrid
@onready var options_hint: Label = $Root/OptionsPanel/MarginContainer/OptionsLayout/OptionsHint
@onready var decision_message: Label = $Root/DecisionMessage

var _value_labels: Dictionary = {}
var _story_pages: Array[String] = []
var _is_confirming_decision := false
var _selected_option_style: StyleBoxFlat

func _ready() -> void:
	_selected_option_style = StyleBoxFlat.new()
	_selected_option_style.bg_color = Color.BLACK
	_selected_option_style.corner_radius_top_left = 2
	_selected_option_style.corner_radius_top_right = 2
	_selected_option_style.corner_radius_bottom_right = 2
	_selected_option_style.corner_radius_bottom_left = 2
	_build_rows()
	if get_node_or_null("/root/GameData") != null:
		GameData.stats_changed.connect(update_stats)
	if get_node_or_null("/root/StoryState") != null:
		StoryState.story_changed.connect(update_story)
		StoryState.selection_changed.connect(update_options)
		StoryState.mode_changed.connect(update_story_mode)
		StoryState.focus_changed.connect(update_story_mode)
	update_stats()
	update_story()
	update_story_mode()

func _unhandled_input(event: InputEvent) -> void:
	if get_node_or_null("/root/StoryState") == null:
		return
	if event.is_action_pressed("story_toggle_mode"):
		StoryState.toggle_mode()
		get_viewport().set_input_as_handled()
		return
	if StoryState.mode != StoryState.Mode.STORY:
		return
	if event.is_action_pressed("story_focus_toggle"):
		StoryState.toggle_focus()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_confirm"):
		_confirm_or_continue()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		StoryState.set_mode(StoryState.Mode.AVATAR)
		get_viewport().set_input_as_handled()
	elif StoryState.focus == StoryState.Focus.OPTIONS:
		if event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
			StoryState.select_option(-1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
			StoryState.select_option(1)
			get_viewport().set_input_as_handled()
	elif StoryState.focus == StoryState.Focus.STORY:
		if event.is_action_pressed("move_down") or event.is_action_pressed("ui_down"):
			StoryState.next_story_page(_story_pages.size())
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("move_up") or event.is_action_pressed("ui_up"):
			StoryState.previous_story_page()
			get_viewport().set_input_as_handled()

func update_stats() -> void:
	if get_node_or_null("/root/GameData") == null:
		return
	for stat_id in PROJEKT_STATS + SCHULE_STATS + AG_STATS:
		_set_value(stat_id, str(GameData.get_stat_display(stat_id)))
	_set_value("lt_akt", str(GameData.get_stat_display("lt_akt")))
	_set_value("lt_reg", str(GameData.get_stat_display("lt_reg")))
	_set_value("aufmerksamkeit", GameData.get_highest_label_suffix(AUFMERKSAMKEIT_STATS))
	_set_value("interpretation", GameData.get_highest_label_suffix(INTERPRETATION_STATS))

func update_story() -> void:
	if get_node_or_null("/root/StoryState") == null:
		return
	_story_pages = _paginate_text(StoryState.get_story_hook())
	if _story_pages.is_empty():
		_story_pages.append("")
	var scene_title := StoryState.get_scene_title()
	story_title.text = "Beobachtungen \"%s\"" % scene_title if scene_title != "" else "Beobachtungen"
	var page_index := clampi(StoryState.story_page_index, 0, _story_pages.size() - 1)
	story_text.text = _story_pages[page_index]
	story_hint.text = "%d/%d  A/Enter weiter  Tab/RB Fokus  E/Y Modus" % [
		page_index + 1,
		_story_pages.size(),
	]
	update_options()
	update_story_mode()

func update_options() -> void:
	if get_node_or_null("/root/StoryState") == null:
		return
	for child in options_grid.get_children():
		child.queue_free()
	var options := StoryState.get_options()
	for i in range(options.size()):
		var option = options[i]
		if not (option is Dictionary):
			continue
		var row := PanelContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if i == StoryState.selected_option_index:
			row.add_theme_stylebox_override("panel", _selected_option_style)
		options_grid.add_child(row)

		var row_margin := MarginContainer.new()
		row_margin.add_theme_constant_override("margin_left", 10)
		row_margin.add_theme_constant_override("margin_top", 4)
		row_margin.add_theme_constant_override("margin_right", 10)
		row_margin.add_theme_constant_override("margin_bottom", 4)
		row.add_child(row_margin)

		var option_label := Label.new()
		option_label.text = "%d. %s" % [i + 1, String(option.get("option_text", ""))]
		option_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		option_label.add_theme_font_size_override("font_size", 18)
		option_label.add_theme_constant_override("line_spacing", 0)
		option_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option_label.add_theme_color_override("font_color", Color.WHITE if i == StoryState.selected_option_index else Color.BLACK)
		row_margin.add_child(option_label)
	options_hint.text = "W/S wählen  A/Enter weiter/bestätigen"

func update_story_mode() -> void:
	if get_node_or_null("/root/StoryState") == null:
		return
	var story_active := StoryState.mode == StoryState.Mode.STORY
	story_panel.modulate = Color(1.0, 1.0, 1.0, 1.0) if story_active and StoryState.focus == StoryState.Focus.STORY else Color(0.78, 0.78, 0.78, 1.0)
	options_panel.modulate = Color(1.0, 1.0, 1.0, 1.0) if story_active and StoryState.focus == StoryState.Focus.OPTIONS else Color(0.78, 0.78, 0.78, 1.0)
	story_hint.visible = story_active
	options_hint.visible = story_active

func _build_rows() -> void:
	_value_labels.clear()
	for child in [projekt_grid, schule_grid, leitung_grid, ag_grid]:
		for existing in child.get_children():
			existing.queue_free()
	for stat_id in PROJEKT_STATS:
		_add_stat_row(projekt_grid, stat_id)
	for stat_id in SCHULE_STATS:
		_add_stat_row(schule_grid, stat_id)
	_add_stat_row(leitung_grid, "lt_akt")
	_add_stat_row(leitung_grid, "lt_reg")
	_add_custom_row(leitung_grid, "Aufmerksamkeit", "aufmerksamkeit")
	_add_custom_row(leitung_grid, "Interpretation", "interpretation")
	for stat_id in AG_STATS:
		_add_stat_row(ag_grid, stat_id)

func _add_stat_row(grid: GridContainer, stat_id: String) -> void:
	var label := GameData.get_stat_label(stat_id) if get_node_or_null("/root/GameData") != null else stat_id
	_add_custom_row(grid, label, stat_id)

func _add_custom_row(grid: GridContainer, label_text: String, value_key: String) -> void:
	var label := Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", CORNER_TEXT_COLOR)
	grid.add_child(label)

	var value := Label.new()
	value.text = "-"
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.add_theme_font_size_override("font_size", 22)
	value.add_theme_color_override("font_color", CORNER_TEXT_COLOR)
	grid.add_child(value)
	_value_labels[value_key] = value

func _set_value(key: String, value: String) -> void:
	if _value_labels.has(key):
		_value_labels[key].text = value

func _format_number(value: float) -> String:
	return str(int(round(value))) if is_equal_approx(value, round(value)) else "%.1f" % value

func _confirm_or_continue() -> void:
	if _is_confirming_decision:
		return
	if StoryState.story_page_index < _story_pages.size() - 1:
		StoryState.next_story_page(_story_pages.size())
		return
	if StoryState.get_options().is_empty():
		return
	StoryState.apply_selected_option_effects()
	_is_confirming_decision = true
	decision_message.text = "Entscheidung getroffen"
	decision_message.visible = true
	await get_tree().create_timer(0.8).timeout
	decision_message.visible = false
	StoryState.advance_story()
	_is_confirming_decision = false

func _paginate_text(text: String) -> Array[String]:
	var words := text.split(" ", false)
	var pages: Array[String] = []
	var current := ""
	for word in words:
		var candidate := word if current == "" else current + " " + word
		if candidate.length() > STORY_PAGE_CHAR_LIMIT and current != "":
			pages.append(current)
			current = word
		else:
			current = candidate
	if current != "":
		pages.append(current)
	return pages
