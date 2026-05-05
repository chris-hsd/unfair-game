extends CharacterBody2D

@export var speed: float = 80.0

var character: CharacterDef
var personality: Personality

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var last_dir: String = "S"

func _ready() -> void:
	add_to_group("stats_owner")
	character = GameState.current_character
	if character != null:
		if character.sprite_frames != null:
			sprite.sprite_frames = character.sprite_frames
		personality = character.personality
	_play_idle()

func _physics_process(_delta: float) -> void:
	var input_vec := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_vec * speed
	move_and_slide()

	if input_vec.length() > 0.1:
		last_dir = _dir_from_vector(input_vec)
		sprite.play("walk_" + last_dir)
	else:
		_play_idle()

func _play_idle() -> void:
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation("idle"):
		if sprite.animation != &"idle":
			sprite.play("idle")
	else:
		sprite.stop()
		sprite.animation = &"walk_S"
		sprite.frame = 0

func _dir_from_vector(v: Vector2) -> String:
	var angle := rad_to_deg(v.angle())
	if angle < 0:
		angle += 360.0
	# 0° = E, 90° = S (Godot Y-down), 180° = W, 270° = N
	var sectors := ["E", "SE", "S", "SW", "W", "NW", "N", "NE"]
	var idx := int(round(angle / 45.0)) % 8
	return sectors[idx]
