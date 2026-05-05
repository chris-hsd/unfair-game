extends Control

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_confirm"):
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file("res://scenes/character_select.tscn")
