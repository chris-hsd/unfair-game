extends Node2D

@export var bg_color: Color = Color(0.98, 0.96, 0.92)

@onready var background: ColorRect = $Background

func _ready() -> void:
	background.color = bg_color

func load_scene_objects(scene_id: String) -> void:
	print("scene_world: loading objects for %s" % scene_id)
