extends Node

@export var project: Project

func _ready() -> void:
	add_to_group("current_project")
