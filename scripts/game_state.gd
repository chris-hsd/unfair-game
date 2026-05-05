extends Node

const _CHARACTER_PATHS := [
	"res://assets/characters/old_man/old_man.tres",
	"res://assets/characters/young_woman/young_woman.tres",
]

var characters: Array[CharacterDef] = []
var current_character: CharacterDef

func _ready() -> void:
	for p in _CHARACTER_PATHS:
		var c := load(p) as CharacterDef
		if c != null:
			characters.append(c)
	if current_character == null and not characters.is_empty():
		current_character = characters[0]

func set_character_by_id(id: StringName) -> void:
	for c in characters:
		if c.id == id:
			current_character = c
			return

func get_character_id() -> StringName:
	return current_character.id if current_character else &""
