extends Control

@onready var preview: AnimatedSprite2D = $Center/Preview
@onready var name_label: Label = $Center/Name

var _index: int = 0

func _ready() -> void:
	if GameState.characters.is_empty():
		push_error("GameState has no characters registered")
		return
	if GameState.current_character != null:
		_index = max(0, GameState.characters.find(GameState.current_character))
	_show(_index)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		_show((_index - 1 + GameState.characters.size()) % GameState.characters.size())
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right"):
		_show((_index + 1) % GameState.characters.size())
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_confirm"):
		GameState.current_character = GameState.characters[_index]
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file("res://scenes/game.tscn")

func _show(i: int) -> void:
	_index = i
	var c: CharacterDef = GameState.characters[i]
	preview.sprite_frames = c.sprite_frames
	preview.play("walk_S")
	name_label.text = c.display_name
