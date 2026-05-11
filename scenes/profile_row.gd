extends HBoxContainer

var entry_id := ""

@onready var name_label: Label = $ExperienceCell/Layout/NameLabel
@onready var icon: TextureRect = $ExperienceCell/Layout/Icon
@onready var percent_label: Label = $PercentCell/PercentLabel
@onready var interpretation_label: Label = $InterpretationCell/InterpretationLabel

func populate(entry: Dictionary, icon_texture: Texture2D) -> void:
	entry_id = String(entry.get("id", ""))
	name_label.text = _short_experience_name(String(entry.get("name", "")))
	icon.texture = icon_texture
	set_percent(int(entry.get("percentage", 0)))
	interpretation_label.text = String(entry.get("interpretation", ""))

func set_percent(value: int) -> void:
	percent_label.text = "%d%%" % value

func _short_experience_name(name: String) -> String:
	if name.begins_with("Pfad der "):
		return name.trim_prefix("Pfad der ")
	return name
