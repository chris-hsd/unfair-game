extends Node

const _CHARACTER_PATHS := [
	"res://assets/characters/old_man/old_man.tres",
	"res://assets/characters/young_woman/young_woman.tres",
]

var characters: Array[CharacterDef] = []
var _current_character: CharacterDef

var current_character: CharacterDef:
	get:
		return _current_character
	set(value):
		_current_character = value
		if value != null and get_node_or_null("/root/GameData") != null:
			GameData.set_avatar(String(value.id))

func _ready() -> void:
	for p in _CHARACTER_PATHS:
		var c := load(p) as CharacterDef
		if c != null:
			characters.append(c)

func set_character_by_id(id: StringName) -> void:
	for c in characters:
		if c.id == id:
			current_character = c
			return

func get_character_id() -> StringName:
	return _current_character.id if _current_character else &""
