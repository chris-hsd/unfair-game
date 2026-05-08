extends CanvasLayer

const PROJEKT_STATS: Array[String] = ["proj_sicht", "proj_ress", "proj_transf", "proj_stab"]
const SCHULE_STATS: Array[String] = ["sch_vert", "sch_rep", "sch_norm", "sch_unt"]
const AG_STATS: Array[String] = ["ag_anerk", "ag_bet", "ag_komm", "ag_abh"]
const AUFMERKSAMKEIT_STATS: Array[String] = ["lt_aufm_leist", "lt_aufm_sicht", "lt_aufm_foerd"]
const INTERPRETATION_STATS: Array[String] = ["lt_int_def", "lt_int_pot", "lt_int_str"]

@onready var projekt_grid: GridContainer = $Root/ProjektPanel/MarginContainer/Grid
@onready var schule_grid: GridContainer = $Root/SchulePanel/MarginContainer/Grid
@onready var leitung_grid: GridContainer = $Root/LeitungPanel/MarginContainer/Grid
@onready var ag_grid: GridContainer = $Root/AgPanel/MarginContainer/Grid

var _value_labels: Dictionary = {}

func _ready() -> void:
	_build_rows()
	if get_node_or_null("/root/GameData") != null:
		GameData.stats_changed.connect(update_stats)
	update_stats()

func update_stats() -> void:
	if get_node_or_null("/root/GameData") == null:
		return
	for stat_id in PROJEKT_STATS + SCHULE_STATS + AG_STATS:
		_set_value(stat_id, _format_number(GameData.get_stat_value(stat_id)))
	_set_value("lt_akt", _format_number(GameData.get_stat_value("lt_akt")))
	_set_value("lt_reg", _format_number(GameData.get_stat_value("lt_reg")))
	_set_value("aufmerksamkeit", GameData.get_highest_label(AUFMERKSAMKEIT_STATS))
	_set_value("interpretation", GameData.get_highest_label(INTERPRETATION_STATS))

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
	grid.add_child(label)

	var value := Label.new()
	value.text = "-"
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value.add_theme_font_size_override("font_size", 22)
	grid.add_child(value)
	_value_labels[value_key] = value

func _set_value(key: String, value: String) -> void:
	if _value_labels.has(key):
		_value_labels[key].text = value

func _format_number(value: float) -> String:
	return str(int(round(value))) if is_equal_approx(value, round(value)) else "%.1f" % value
