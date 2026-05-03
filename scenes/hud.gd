extends CanvasLayer

@export var personality: Personality

@onready var player_value: Label = $Root/Panel/MarginContainer/StatsGrid/LabelPlayerValue
@onready var aktionsmodus_value: Label = $Root/Panel/MarginContainer/StatsGrid/LabelAktionsmodusValue
@onready var fokus_value: Label = $Root/Panel/MarginContainer/StatsGrid/LabelFokusValue
@onready var regelbindung_value: Label = $Root/Panel/MarginContainer/StatsGrid/LabelRegelbindungValue
@onready var interpretation_value: Label = $Root/Panel/MarginContainer/StatsGrid/LabelInterpretationValue

@onready var projekt_value: Label = $Root/ProjectPanel/MarginContainer/ProjectGrid/LabelProjektValue
@onready var ressourcenbedarf_value: Label = $Root/ProjectPanel/MarginContainer/ProjectGrid/LabelRessourcenbedarfValue
@onready var aussenwirkung_value: Label = $Root/ProjectPanel/MarginContainer/ProjectGrid/LabelAussenwirkungValue
@onready var transformation_value: Label = $Root/ProjectPanel/MarginContainer/ProjectGrid/LabelTransformationValue

var _project: Project

func _ready() -> void:
	if personality != null:
		personality.changed.connect(update_stats)
	update_stats()
	_resolve_project.call_deferred()

func _resolve_project() -> void:
	var holder := get_tree().get_first_node_in_group("current_project")
	if holder != null:
		_project = holder.get("project")
		if _project != null:
			_project.changed.connect(update_project)
	update_project()

func update_stats() -> void:
	if personality == null:
		player_value.text = "—"
		aktionsmodus_value.text = "—"
		fokus_value.text = "Keine Personality"
		regelbindung_value.text = "—"
		interpretation_value.text = "—"
		return
	player_value.text = personality.player
	aktionsmodus_value.text = str(personality.aktionsmodus)
	fokus_value.text = Personality.Focus.keys()[personality.aufmerksamkeit]
	regelbindung_value.text = "%.2f" % personality.regelbindung
	interpretation_value.text = Personality.Interpretation.keys()[personality.interpretation]

func update_project() -> void:
	if _project == null:
		projekt_value.text = "Kein Projekt"
		ressourcenbedarf_value.text = "—"
		aussenwirkung_value.text = "—"
		transformation_value.text = "—"
		return
	projekt_value.text = _project.titel
	ressourcenbedarf_value.text = Project.Amount.keys()[_project.ressourcenbedarf]
	aussenwirkung_value.text = Project.Amount.keys()[_project.aussenwirkung]
	transformation_value.text = Project.Amount.keys()[_project.transformation]
