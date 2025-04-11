extends Node2D

const BULLET = preload("res://scenes/guns/rocket.tscn")

@onready var muzzle = $Marker2D
@onready var anim_sprite = $AnimatedSprite2D

var on_cooldown = false
var x_cursor = 128

func _ready():
	anim_sprite.play("default")
	add_to_group("player_gun")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	look_at(get_global_mouse_position())
	
	rotation_degrees = wrap(rotation_degrees, 0, 360)
	if rotation_degrees > 90 and rotation_degrees < 270:
		scale.y = -1
	else:
		scale.y = 1
	
	if Input.is_action_just_pressed("shoot") and not on_cooldown:
		on_cooldown = true
		anim_sprite.play("shoot")
		var bullet_instance = BULLET.instantiate()
		get_tree().root.add_child(bullet_instance)
		bullet_instance.global_position = muzzle.global_position
		bullet_instance.rotation = rotation

func _on_animated_sprite_2d_animation_finished() -> void:
	anim_sprite.play("default")
	on_cooldown = false
